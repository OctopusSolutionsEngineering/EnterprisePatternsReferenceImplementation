import json
import subprocess
import sys

if 'get_octopusvariable' not in globals():
    print('Script must be run as an Octopus step')
    sys.exit(1)


def execute(args, cwd=None, env=None, print_args=None, print_output=printverbose):
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

    for resource in resources:
        url = resource.get('values', {}).get('git_library_persistence_settings', [{'url': None}])[0].get('url', None)
        space_id = resource.get('values', {}).get('space_id', None)
        name = resource.get('values', {}).get('name', None)

        print(space_id + ' "' + name + '" ' + url)
