import subprocess
import time
import os
import re
import json
import urllib.request
import urllib.parse

# If this script is not being run as part of an Octopus step, return variables from environment variables.
if "get_octopusvariable" not in globals():
    def get_octopusvariable(variable):
        if variable == 'Octopus.Project.Name':
            return os.environ['OCTOPUS_PROJECT_NAME']

        return ""

# If this script is not being run as part of an Octopus step, print directly to std out.
if "printverbose" not in globals():
    def printverbose(msg):
        print(msg)


def execute(args, cwd=None, env=None, print_args=None, print_output=printverbose):
    """
        The execute method provides the ability to execute external processes while capturing and returning the
        output to std err and std out and exit code.
    """
    process = subprocess.Popen(args,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE,
                               text=True,
                               cwd=cwd,
                               env=env)
    stdout, stderr = process.communicate()
    retcode = process.returncode

    if print_args is not None:
        print_output(' '.join(args))

    if print_output is not None:
        print_output(stdout)
        print_output(stderr)

    return stdout, stderr, retcode


cac_username = '${cac_username}'
cac_password = '${cac_password}'
backend = '${backend}'
project_name = re.sub('[^a-zA-Z0-9]', '_', get_octopusvariable('Octopus.Project.Name').lower())
template_repo = 'http://' + cac_username + ':' + cac_password + '@gitea:3000/octopuscac/' + project_name + '.git'
branch = 'main'

with open('backend.tf', 'w') as f:
    f.write("""
    terraform {
        backend "pg" {
      }
      required_providers {
        octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }
      }
    }
    """)

execute(['git', 'config', '--global', 'user.email', "octopus@octopus.com"])
execute(['git', 'config', '--global', 'user.name', "Octopus Server"])

execute(['terraform', 'init', '-no-color',
         '-backend-config=conn_str=postgres://terraform:terraform@terraformdb:5432/' + backend + '?sslmode=disable'])

print("✓ - Up to date")
print("▶ - Can automatically merge")
print("× - Merge conflict")

workspaces, _, _ = execute(['terraform', 'workspace', 'list'])
workspaces = workspaces.replace('*', '').split('\n')

for workspace in workspaces:
    trimmed_workspace = workspace.strip()

    if trimmed_workspace == "default" or trimmed_workspace == "":
        continue

    execute(['terraform', 'workspace', 'select', trimmed_workspace])

    state_json, _, _ = execute(['terraform', 'show', '-json'])
    state = json.loads(state_json)

    resources = [x for x in state.get('values', {}).get('root_module', {}).get('resources', {}) if
                 x.get('type', '') == 'octopusdeploy_project']

    # The outputs allow us to contact the downstream instance)
    api_key, _, api_key_retcode = execute(['terraform', 'output', '-raw', 'octopus_apikey'], print_output=None)
    server, _, server_retcode = execute(['terraform', 'output', '-raw', 'octopus_server'])
    space_id, _, space_id_retcode = execute(['terraform', 'output', '-raw', 'octopus_space_id'])
    space_name = None

    # Find the downstream space name
    if api_key_retcode == 0 and server_retcode == 0 and space_id_retcode == 0:
        url = server + '/api/Spaces/' + space_id
        headers = {
            "X-Octopus-ApiKey": api_key,
            'Accept': 'application/json'
        }
        request = urllib.request.Request(url, headers=headers)
        response = None
        for x in range(3):
            response = urllib.request.urlopen(request)
            if response.getcode() == 200:
                break
            time.sleep(5)

        response_data = response.read().decode("utf-8")
        data = json.loads(response_data)
        space_name = data.get("Name", None)

    for resource in resources:
        git_settings = resource.get('values', {}).get('git_library_persistence_settings', [{}])
        url = git_settings[0].get('url', None) if len(git_settings) != 0 else None
        space_id = resource.get('values', {}).get('space_id', None)
        name = resource.get('values', {}).get('name', None)

        if url is not None:
            os.mkdir(trimmed_workspace)

            execute(['git', 'clone', url, trimmed_workspace])
            execute(['git', 'remote', 'add', 'upstream', template_repo], cwd=trimmed_workspace)
            execute(['git', 'fetch', '--all'], cwd=trimmed_workspace)
            execute(['git', 'checkout', '-b', 'upstream-' + branch, 'upstream/' + branch], cwd=trimmed_workspace)

            if branch != 'master' and branch != 'main':
                execute(['git', 'checkout', '-b', branch, 'origin/' + branch], cwd=trimmed_workspace)
            else:
                execute(['git', 'checkout', branch], cwd=trimmed_workspace)

            merge_base, _, _ = execute(['git', 'merge-base', branch, 'upstream-' + branch], cwd=trimmed_workspace)
            merge_source_current_commit, _, _ = execute(['git', 'rev-parse', 'upstream-' + branch],
                                                        cwd=trimmed_workspace)
            _, _, merge_result = execute(['git', 'merge', '--no-commit', '--no-ff', 'upstream-' + branch],
                                         cwd=trimmed_workspace)

            if merge_base == merge_source_current_commit:
                print(str(space_name or space_id or '') + ' "' + str(name or '') + '" ' + str(url or '') + " ✓")
            elif merge_result != 0:
                print(str(space_name or space_id or '') + ' "' + str(name or '') + '" ' + str(url or '') + " ×")
            else:
                print(str(space_name or space_id or '') + ' "' + str(name or '') + '" ' + str(url or '') + " ▶")
