import argparse
import os
import re
import subprocess
import sys
from datetime import datetime
from urllib.parse import urlparse

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


def init_argparse():
    parser = argparse.ArgumentParser(
        usage='%(prog)s [OPTION] [FILE]...',
        description='Fork a GitHub repo'
    )
    parser.add_argument('--ignore-all-changes',
                        action='store',
                        default=get_octopusvariable_quiet('Exported.Project.IgnoreAllChanges'),
                        help='Set to true to set the "lifecycle.ignore_changes" ' +
                             'setting on each exported resource to "all"')
    parser.add_argument('--terraform-backend',
                        action='store',
                        default=get_octopusvariable_quiet('ThisInstance.Terraform.Backend'),
                        help='Set this to the name of the Terraform backend to be included in the generated module.')
    parser.add_argument('--upload-space-id',
                        action='store',
                        default=get_octopusvariable_quiet('Octopus.UploadSpace.Id'),
                        help='Set this to the space ID of the Octopus space where ' +
                             'the resulting package will be uploaded to.')
    parser.add_argument('--ignore-cac-managed-values',
                        action='store',
                        default='false',
                        help='Set this to true to exclude cac managed values like non-secret variables, ' +
                             'deployment processes, and project versioning into the Terraform module. ' +
                             'Set to false to have these values embedded into the module.')

    return parser.parse_known_args()


# Variable precondition checks
if len(get_octopusvariable_quiet('ThisInstance.Server.Url')) == 0:
    print("ThisInstance.Server.Url must be defined")
    sys.exit(1)

if len(get_octopusvariable_quiet('ThisInstance.Api.Key')) == 0:
    print("ThisInstance.Api.Key must be defined")
    sys.exit(1)

parser, _ = init_argparse()

print("Pulling the Docker images")
execute(['docker', 'pull', 'octopussamples/octoterra'])
execute(['docker', 'pull', 'octopusdeploy/octo'])

# Find out the IP address of the Octopus container
parsed_url = urlparse(get_octopusvariable_quiet('ThisInstance.Server.Url'))
octopus, _, _ = execute(['dig', '+short', parsed_url.hostname])

print("Octopus container hostname: " + parsed_url.hostname)
print("Octopus container IP: " + octopus.strip())

# Assume we don't ignore all changes. Exported.Project.IgnoreAllChanges can override this behaviour.
ignoreAllChanges = parser.ignore_all_changes if len(parser.ignore_all_changes) != 0 else "false"

# Assume a postgres backend unless ThisInstance.Terraform.Backend is set
terraformBackend = parser.terraform_backend if len(parser.terraform_backend) != 0 else "pg"

# Assume we upload to the same space unless Octopus.UploadSpace.Id is set
uploadSpace = parser.upload_space_id if len(parser.upload_space_id) != 0 \
    else get_octopusvariable_quiet('Octopus.Space.Id')

stdout, _, octoterra_exit = execute(['docker', 'run',
                        '--rm',
                        '--add-host=' + parsed_url.hostname + ':' + octopus.strip(),
                        '-v', os.getcwd() + "/export:/export",
                        'octopussamples/octoterra',
                        # the url of the instance
                        '-url', get_octopusvariable_quiet('ThisInstance.Server.Url'),
                        # the api key used to access the instance
                        '-apiKey', get_octopusvariable_quiet('ThisInstance.Api.Key'),
                        # add a postgres backend to the generated modules
                        '-terraformBackend', terraformBackend,
                        # dump the generated HCL to the console
                        '-console',
                        # dump the project from the current space
                        '-space', get_octopusvariable_quiet('Octopus.Space.Id'),
                        # the name of the project to serialize
                        '-projectName', get_octopusvariable_quiet('Octopus.Project.Name'),
                        # ignoreProjectChanges can be set to ignore all changes to the project, variables, runbooks etc
                        '-ignoreProjectChanges=' + ignoreAllChanges,
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
                        # This is a management runbook that we do not wish to export
                        '-excludeRunbookRegex', '__ .*',
                        # This is library variable set used by excluded runbooks, and so we don't want to link to it in
                        # the export
                        '-excludeLibraryVariableSet', 'Octopus Server',
                        # This is library variable set used by excluded runbooks, and so we don't want to link to it in
                        # the export
                        '-excludeLibraryVariableSet', 'This Instance',
                        # This is library variable set used by excluded runbooks, and so we don't want to link to it in
                        # the export
                        '-excludeLibraryVariableSet', 'Azure',
                        # This is library variable set used by excluded runbooks, and so we don't want to link to it in
                        # the export
                        '-excludeLibraryVariableSet', 'Export Options',
                        # This is library variable set used by excluded runbooks, and so we don't want to link to it in
                        # the export
                        '-excludeLibraryVariableSet', 'Git',
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
                        '-dest', '/export'])

print(stdout)

if not octoterra_exit == 0:
    print("Octoterra failed. Please check the logs for more information.")
    sys.exit(1)

date = datetime.now().strftime('%Y.%m.%d.%H%M%S')

stdout, _, _ = execute(['docker', 'run',
                        '--rm',
                        '--add-host=' + parsed_url.hostname + ':' + octopus.strip(),
                        '-v', os.getcwd() + "/export:/export",
                        'octopusdeploy/octo',
                        'pack',
                        '--format', 'zip',
                        '--id', re.sub('[^0-9a-zA-Z]', '_', get_octopusvariable_quiet('Octopus.Project.Name')),
                        '--version', date,
                        '--basePath', '/export',
                        '--outFolder', '/export'])

print(stdout)

stdout, _, _ = execute(['docker', 'run',
                        '--rm',
                        '--add-host=' + parsed_url.hostname + ':' + octopus.strip(),
                        '-v', os.getcwd() + "/export:/export",
                        'octopusdeploy/octo',
                        'push',
                        '--apiKey', get_octopusvariable_quiet('ThisInstance.Api.Key'),
                        '--server', get_octopusvariable_quiet('ThisInstance.Server.Url'),
                        '--space', uploadSpace,
                        '--package', '/export/' +
                        re.sub('[^0-9a-zA-Z]', '_',
                               get_octopusvariable_quiet('Octopus.Project.Name')) + '.' + date + '.zip',
                        '--replace-existing'])

print(stdout)

print("##octopus[stdout-default]")

print("Done")
