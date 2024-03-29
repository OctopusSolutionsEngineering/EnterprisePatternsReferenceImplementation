import subprocess
import os
import re
import json
import sys

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


project_dir = re.sub('[^a-zA-Z0-9]', '_', get_octopusvariable('Octopus.Project.Name'))
sanitized_project_name = backend = re.sub('[^a-zA-Z0-9]', '_', get_octopusvariable('Octopus.Project.Name').lower())
project_space_population_dir = project_dir + '/space_population'
octopus_server = get_octopusvariable("ManagedTenant.Octopus.Url")
octopus_space_id = get_octopusvariable("ManagedTenant.Octopus.SpaceId")
octopus_api_key = get_octopusvariable("ManagedTenant.Octopus.ApiKey")
tenant_name = get_octopusvariable("Octopus.Deployment.Tenant.Name")


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


def init_project():
    execute(['terraform', 'init', '-no-color',
             '-backend-config=conn_str=postgres://terraform:terraform@terraformdb:5432/' + backend + '?sslmode=disable'],
            cwd=project_space_population_dir)


def apply_project(project_name, space_name):
    print("Updating " + project_name + " in space " + space_name)
    execute(['terraform', 'apply', '-no-color', '-auto-approve',
             '-var=octopus_server=' + octopus_server,
             '-var=octopus_space_id=' + octopus_space_id,
             '-var=octopus_apikey=' + octopus_api_key,
             '-var=project_' + sanitized_project_name + '_name=' + project_name
             ], cwd=project_space_population_dir)


def find_downstream_projects(apply_project_callback):
    workspaces, _, _ = execute(['terraform', 'workspace', 'list'], cwd=project_space_population_dir)
    workspaces = workspaces.replace('*', '').split('\n')

    for workspace in workspaces:
        trimmed_workspace = workspace.strip()

        if trimmed_workspace == "default" or trimmed_workspace == "":
            continue

        execute(['terraform', 'workspace', 'select', trimmed_workspace], cwd=project_space_population_dir)

        octopus_space_name, _, server_retcode = execute(['terraform', 'output', '-raw', 'octopus_space_name'],
                                                        cwd=project_space_population_dir)

        # We only work on the projects associated with the current tenant
        if not octopus_space_name == tenant_name:
            continue

        state_json, _, ret_code = execute(['terraform', 'show', '-json'], cwd=project_space_population_dir)

        if ret_code != 0:
            print(state_json)
            sys.exit(1)

        state = json.loads(state_json)

        resources = [x for x in state.get('values', {}).get('root_module', {}).get('resources', {}) if
                     x.get('type', '') == 'octopusdeploy_project']

        for resource in resources:
            name = resource.get('values', {}).get('name', None)

            if name is not None:
                apply_project_callback(name, octopus_space_name)


init_project()
find_downstream_projects(apply_project)
