import json
import re
import subprocess
import os

# If this script is not being run as part of an Octopus step, return variables from environment variables.
if "get_octopusvariable" not in globals():
    def get_octopusvariable(variable):
        if variable == 'Octopus.Project.Name':
            return os.environ['OCTOPUS_PROJECT_NAME']

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


backend = re.sub('[^a-zA-Z0-9]', '_', get_octopusvariable('Octopus.Project.Name').lower())

with open('backend.tf', 'w') as f:
    f.write("""
    terraform {
        backend "pg" {
      }
      required_providers {
        octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.2" }
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
    api_key, _, api_key_retcode = execute(['terraform', 'output', '-raw', 'octopus_apikey'], print_output=None)
    server, _, server_retcode = execute(['terraform', 'output', '-raw', 'octopus_server'])
    space_id, _, space_id_retcode = execute(['terraform', 'output', '-raw', 'octopus_space_id'])
    space_name, _, _ = execute(['terraform', 'output', '-raw', 'octopus_space_name'])

    for resource in resources:
        git_settings = resource.get('values', {}).get('git_library_persistence_settings', [{}])
        url = git_settings[0].get('url', None) if len(git_settings) != 0 else None
        space_id = resource.get('values', {}).get('space_id', None)
        name = resource.get('values', {}).get('name', None)

        print(str(space_name or space_id or '') + ' "' + str(name or '') + '" ' + str(url or ''))
