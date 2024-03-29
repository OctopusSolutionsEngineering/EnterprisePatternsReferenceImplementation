import argparse
import os
import re
import socket
import subprocess
import sys
from datetime import datetime
from urllib.parse import urlparse
from itertools import chain
import platform
from urllib.request import urlretrieve
import zipfile

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


def get_octopusvariable_quiet(variable):
    """
    Gets an octopus variable, or an empty string if it does not exist.
    :param variable: The variable name
    :return: The variable value, or an empty string if the variable does not exist
    """
    try:
        return get_octopusvariable(variable)
    except:
        return ''


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


def is_windows():
    return platform.system() == 'Windows'


def init_argparse():
    parser = argparse.ArgumentParser(
        usage='%(prog)s [OPTION] [FILE]...',
        description='Serialize an Octopus project to a Terraform module'
    )
    parser.add_argument('--ignore-all-changes',
                        action='store',
                        default=get_octopusvariable_quiet(
                            'SerializeProject.Exported.Project.IgnoreAllChanges') or get_octopusvariable_quiet(
                            'Exported.Project.IgnoreAllChanges') or 'false',
                        help='Set to true to set the "lifecycle.ignore_changes" ' +
                             'setting on each exported resource to "all"')
    parser.add_argument('--terraform-backend',
                        action='store',
                        default=get_octopusvariable_quiet(
                            'SerializeProject.ThisInstance.Terraform.Backend') or get_octopusvariable_quiet(
                            'ThisInstance.Terraform.Backend') or 'pg',
                        help='Set this to the name of the Terraform backend to be included in the generated module.')
    parser.add_argument('--server-url',
                        action='store',
                        default=get_octopusvariable_quiet(
                            'SerializeProject.ThisInstance.Server.Url') or get_octopusvariable_quiet(
                            'ThisInstance.Server.Url'),
                        help='Sets the server URL that holds the project to be serialized.')
    parser.add_argument('--api-key',
                        action='store',
                        default=get_octopusvariable_quiet(
                            'SerializeProject.ThisInstance.Api.Key') or get_octopusvariable_quiet(
                            'ThisInstance.Api.Key'),
                        help='Sets the Octopus API key.')
    parser.add_argument('--space-id',
                        action='store',
                        default=get_octopusvariable_quiet(
                            'SerializeProject.Exported.Space.Id') or get_octopusvariable_quiet(
                            'Exported.Space.Id') or get_octopusvariable_quiet('Octopus.Space.Id'),
                        help='Set this to the space ID containing the project to be serialized.')
    parser.add_argument('--project-name',
                        action='store',
                        default=get_octopusvariable_quiet(
                            'SerializeProject.Exported.Project.Name') or get_octopusvariable_quiet(
                            'Exported.Project.Name') or get_octopusvariable_quiet(
                            'Octopus.Project.Name'),
                        help='Set this to the name of the project to be serialized.')
    parser.add_argument('--upload-space-id',
                        action='store',
                        default=get_octopusvariable_quiet(
                            'SerializeProject.Octopus.UploadSpace.Id') or get_octopusvariable_quiet(
                            'Octopus.UploadSpace.Id') or get_octopusvariable_quiet('Octopus.Space.Id'),
                        help='Set this to the space ID of the Octopus space where ' +
                             'the resulting package will be uploaded to.')
    parser.add_argument('--ignore-cac-managed-values',
                        action='store',
                        default=get_octopusvariable_quiet(
                            'SerializeProject.Exported.Project.IgnoreCacValues') or get_octopusvariable_quiet(
                            'Exported.Project.IgnoreCacValues') or 'false',
                        help='Set this to true to exclude cac managed values like non-secret variables, ' +
                             'deployment processes, and project versioning into the Terraform module. ' +
                             'Set to false to have these values embedded into the module.')
    parser.add_argument('--ignored-library-variable-sets',
                        action='store',
                        default=get_octopusvariable_quiet(
                            'SerializeProject.Exported.Project.IgnoredLibraryVariableSet') or get_octopusvariable_quiet(
                            'Exported.Project.IgnoredLibraryVariableSet'),
                        help='A comma separated list of library variable sets to ignore.')

    return parser.parse_known_args()


def ensure_octo_cli_exists():
    if is_windows():
        print("Checking for the Octopus CLI")
        try:
            stdout, _, exit_code = execute(['octo', 'help'])
            printverbose(stdout)
            if not exit_code == 0:
                raise "Octo CLI not found"
        except:
            print("Downloading the Octopus CLI")
            urlretrieve('https://download.octopusdeploy.com/octopus-tools/9.0.0/OctopusTools.9.0.0.win-x64.zip',
                        'OctopusTools.zip')
            with zipfile.ZipFile('OctopusTools.zip', 'r') as zip_ref:
                zip_ref.extractall(os.getcwd())


def check_docker_exists():
    try:
        stdout, _, exit_code = execute(['docker', 'version'])
        printverbose(stdout)
        if not exit_code == 0:
            raise "Docker not found"
    except:
        print('Docker must be installed: https://docs.docker.com/get-docker/')
        sys.exit(1)


check_docker_exists()
ensure_octo_cli_exists()
parser, _ = init_argparse()

# Variable precondition checks
if len(parser.server_url) == 0:
    print("--server-url, ThisInstance.Server.Url, or SerializeProject.ThisInstance.Server.Url must be defined")
    sys.exit(1)

if len(parser.api_key) == 0:
    print("--api-key, ThisInstance.Api.Key, or ThisInstance.Api.Key must be defined")
    sys.exit(1)

if not is_windows():
    print("Pulling the Docker images")
    execute(['docker', 'pull', 'octopussamples/octoterra'])
    execute(['docker', 'pull', 'octopusdeploy/octo'])

# Find out the IP address of the Octopus container
parsed_url = urlparse(parser.server_url)
octopus = socket.getaddrinfo(parsed_url.hostname, '80')[0][4][0]

print("Octopus hostname: " + parsed_url.hostname)
print("Octopus IP: " + octopus.strip())

# Build the arguments to ignore library variable sets
ignores_library_variable_sets = parser.ignored_library_variable_sets.split(',')
ignores_library_variable_sets_args = [['-excludeLibraryVariableSet', x] for x in ignores_library_variable_sets]

octoterra_image = 'octopussamples/octoterra-windows' if is_windows() else 'octopussamples/octoterra'
octoterra_mount = 'C:/export' if is_windows() else '/export'

os.mkdir(os.getcwd() + '/export')

export_args = ['docker', 'run',
               '--rm',
               '--add-host=' + parsed_url.hostname + ':' + octopus.strip(),
               '-v', os.getcwd() + '/export:' + octoterra_mount,
               octoterra_image,
               # the url of the instance
               '-url', parser.server_url,
               # the api key used to access the instance
               '-apiKey', parser.api_key,
               # add a postgres backend to the generated modules
               '-terraformBackend', parser.terraform_backend,
               # dump the generated HCL to the console
               '-console',
               # dump the project from the current space
               '-space', parser.space_id,
               # the name of the project to serialize
               '-projectName', parser.project_name,
               # ignoreProjectChanges can be set to ignore all changes to the project, variables, runbooks etc
               '-ignoreProjectChanges=' + parser.ignore_all_changes,
               # use data sources to lookup external dependencies (like environments, accounts etc) rather
               # than serialize those external resources
               '-lookupProjectDependencies',
               # for any secret variables, add a default value set to the octostache value of the variable
               # e.g. a secret variable called "database" has a default value of "#{database}"
               '-defaultSecretVariableValues',
               # detach any step templates, allowing the exported project to be used in a new space
               '-detachProjectTemplates',
               # allow the downstream project to move between project groups
               '-ignoreProjectGroupChanges',
               # allow the downstream project to change names
               '-ignoreProjectNameChanges',
               # CaC enabled projects will not export the deployment process, non-secret variables, and other
               # CaC managed project settings if ignoreCacManagedValues is true. It is usually desirable to
               # set this value to true, but it is false here because CaC projects created by Terraform today
               # save some variables in the database rather than writing them to the Git repo.
               '-ignoreCacManagedValues=' + parser.ignore_cac_managed_values,
               # This value is always true. Either this is an unmanaged project, in which case we are never
               # reapplying it; or it is a variable configured project, in which case we need to ignore
               # variable changes, or it is a shared CaC project, in which case we don't use Terraform to
               # manage variables.
               '-ignoreProjectVariableChanges',
               # To have secret variables available when applying a downstream project, they must be scoped
               # to the Sync environment. But we do not need this scoping in the downstream project, so the
               # Sync environment is removed from any variable scopes when serializing it to Terraform.
               '-excludeVariableEnvironmentScopes', 'Sync',
               # Exclude any variables starting with "Private."
               '-excludeProjectVariableRegex', 'Private\\..*',
               # Capture the octopus endpoint, space ID, and space name as output vars. This is useful when
               # querying th Terraform state file to know which space and instance the resources were
               # created in. The scripts used to update downstream projects in bulk work by querying the
               # Terraform state, finding all the downstream projects, and using the space name to only process
               # resources that match the current tenant (because space names and tenant names are the same).
               # The output variables added by this option are octopus_server, octopus_space_id, and
               # octopus_space_name.
               '-includeOctopusOutputVars',
               # Where steps do not explicitly define a worker pool and reference the default one, this
               # option explicitly exports the default worker pool by name. This means if two spaces have
               # different default pools, the exported project still uses the pool that the original project
               # used.
               '-lookUpDefaultWorkerPools',
               # These tenants are linked to the project to support some management runbooks, but should not
               # be exported
               '-excludeAllTenants',
               # The directory where the exported files will be saved
               '-dest', octoterra_mount,
               # This is a management runbook that we do not wish to export
               '-excludeRunbookRegex', '__ .*'] + list(chain(*ignores_library_variable_sets_args))

print("Exporting Terraform module")
stdout, _, octoterra_exit = execute(export_args)

printverbose(stdout)

if not octoterra_exit == 0:
    print("Octoterra failed. Please check the logs for more information.")
    sys.exit(1)

date = datetime.now().strftime('%Y.%m.%d.%H%M%S')

print("Creating Terraform module package")
if is_windows():
    execute(['octo',
             'pack',
             '--format', 'zip',
             '--id', re.sub('[^0-9a-zA-Z]', '_', parser.project_name),
             '--version', date,
             '--basePath', 'C:\\export',
             '--outFolder', 'C:\\export'])
    printverbose(stdout)
else:
    stdout, _, _ = execute(['docker', 'run',
                            '--rm',
                            '--add-host=' + parsed_url.hostname + ':' + octopus.strip(),
                            '-v', os.getcwd() + "/export:/export",
                            'octopusdeploy/octo',
                            'pack',
                            '--format', 'zip',
                            '--id', re.sub('[^0-9a-zA-Z]', '_', parser.project_name),
                            '--version', date,
                            '--basePath', '/export',
                            '--outFolder', '/export'])
    printverbose(stdout)

print("Uploading Terraform module package")
if is_windows():
    stdout, _, _ = execute(['octo',
                            'push',
                            '--apiKey', parser.api_key,
                            '--server', parser.server_url,
                            '--space', parser.upload_space_id,
                            '--package', 'C:\\export\\' +
                            re.sub('[^0-9a-zA-Z]', '_', parser.project_name) + '.' + date + '.zip',
                            '--replace-existing'])
    printverbose(stdout)
else:
    stdout, _, _ = execute(['docker', 'run',
                            '--rm',
                            '--add-host=' + parsed_url.hostname + ':' + octopus.strip(),
                            '-v', os.getcwd() + "/export:/export",
                            'octopusdeploy/octo',
                            'push',
                            '--apiKey', parser.api_key,
                            '--server', parser.server_url,
                            '--space', parser.upload_space_id,
                            '--package', '/export/' +
                            re.sub('[^0-9a-zA-Z]', '_', parser.project_name) + '.' + date + '.zip',
                            '--replace-existing'])
    printverbose(stdout)

print("##octopus[stdout-default]")

print("Done")
