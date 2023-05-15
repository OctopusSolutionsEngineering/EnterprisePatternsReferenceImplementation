import subprocess
import sys
import os
import re
import json

if "get_octopusvariable" not in globals():
    print("Script must be run as an Octopus step")
    sys.exit(1)


simple_print = lambda x: print(x)

def execute(args, cwd=None, print_output=None):
    process = subprocess.Popen(args,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE,
                               text=True,
                               cwd=cwd)
    stdout, stderr = process.communicate()
    retcode = process.returncode

    if print_output is not None:
        print_output(' '.join(args))
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

    resource = [x for x in state.get('values', {}).get('root_module', {}).get('resources', {}) if
                x.get('type', '') == 'octopusdeploy_project']
    url = resource.get('values', {}).get('git_library_persistence_settings', [{'url': None}])[0].get('url', None)
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
        merge_source_current_commit, _, _ = execute(['git', 'rev-parse', 'upstream-' + branch], cwd=trimmed_workspace)
        _, _, merge_result = execute(['git', 'merge', '--no-commit', '--no-ff', 'upstream-' + branch], cwd=trimmed_workspace)

        if merge_base == merge_source_current_commit:
            print(space_id + ' "' + name + '" ' + url + " ✓")
        elif merge_result != 0:
            print(space_id + ' "' + name + '" ' + url + " ×")
        else:
            print(space_id + ' "' + name + '" ' + url + " ▶")