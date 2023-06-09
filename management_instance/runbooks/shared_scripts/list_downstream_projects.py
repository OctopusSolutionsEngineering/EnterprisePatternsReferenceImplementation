import json
import urllib.request
import urllib.parse
import subprocess
import time

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


backend = '${backend}'

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

execute(['terraform', 'init', '-no-color',
         '-backend-config=conn_str=postgres://terraform:terraform@terraformdb:5432/' + backend + '?sslmode=disable'])
workspaces, _, _ = execute(['terraform', 'workspace', 'list'])
workspaces = workspaces.replace('*', '').split('\n')

for workspace in workspaces:
    trimmed_workspace = workspace.strip()

    if trimmed_workspace == 'default' or trimmed_workspace == '':
        continue

    execute(['terraform', 'workspace', 'select', trimmed_workspace])
    workspace_json, _, _, = execute(['terraform', 'show', '-json'])
    state = json.loads(workspace_json)
    resources = [x for x in state.get('values', {}).get('root_module', {}).get('resources', {}) if
                 x.get('type', '') == 'octopusdeploy_project']

    # The outputs allow us to contact the downstream instance)
    api_key, _, api_key_retcode = execute(['terraform', 'output', '-raw', 'octopus_apikey'])
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

        print(str(space_name or space_id or '') + ' "' + str(name or '') + '" ' + str(url or ''))
