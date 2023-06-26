import json
import os
import re
import subprocess

# If this script is not being run as part of an Octopus step, return variables from environment variables.
# Periods are replaced with underscores, and the variable name is converted to uppercase
if "get_octopusvariable" not in globals():
    def get_octopusvariable(variable):
        return os.environ[re.sub('\\.', '_', variable.upper())]
# If this script is not being run as part of an Octopus step, print directly to std out.
if "printverbose" not in globals():
    def printverbose(msg):
        print(msg)


def printverbose_noansi(output):
    """
    Strip ANSI color codes and print the output as verbose
    :param output: The output to print
    """
    output_no_ansi = re.sub('\x1b\[[0-9;]*m', '', output)
    printverbose(output_no_ansi)


def execute(args, cwd=None, env=None, print_args=None, print_output=printverbose_noansi):
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


cac_username = get_octopusvariable('Git.Credentials.Username')
cac_password = get_octopusvariable('Git.Credentials.Password')
cac_proto = get_octopusvariable('Git.Url.Protocol')
cac_host = get_octopusvariable('Git.Url.Host')
cac_org = get_octopusvariable('Git.Url.Organization')
backend = re.sub('[^a-zA-Z0-9]', '_', get_octopusvariable('Octopus.Project.Name').lower())
project_name = re.sub('[^a-zA-Z0-9]', '_', get_octopusvariable('Octopus.Project.Name').lower())
template_repo_url = cac_proto + '://' + cac_host + '/' + cac_org + '/' + project_name + '.git'
template_repo = cac_proto + '://' + cac_username + ':' + cac_password + '@' + cac_host + '/' + cac_org + '/' + project_name + '.git'
branch = 'main'

with open('backend.tf', 'w') as f:
    f.write("""
    terraform {
        backend "pg" {
      }
      required_providers {
        octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.4" }
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
print("Verbose logs contain instructions for resolving merge conflicts.")

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
    space_name, _, _ = execute(['terraform', 'output', '-raw', 'octopus_space_name'])

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
                printverbose('To resolve the conflicts, run the following commands:')
                printverbose('mkdir cac')
                printverbose('cd cac')
                printverbose('git clone ' + url + ' .')
                printverbose('git remote add upstream ' + template_repo_url)
                printverbose('git fetch --all')
                printverbose('git checkout -b upstream-' + branch + ' upstream/' + branch)
                if branch != 'master' and branch != 'main':
                    printverbose('git checkout -b ' + branch + ' origin/' + branch)
                else:
                    printverbose('git checkout ' + branch)
                printverbose('git merge-base ' + branch + ' upstream-' + branch)
                printverbose('git merge --no-commit --no-ff upstream-' + branch)
            else:
                print(str(space_name or space_id or '') + ' "' + str(name or '') + '" ' + str(url or '') + " ▶")
