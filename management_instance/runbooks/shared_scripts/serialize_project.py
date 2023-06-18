import os
import re
import subprocess
import sys
from datetime import datetime
from urllib.parse import urlparse

# If this script is not being run as part of an Octopus step, return variables from environment variables.
if "get_octopusvariable" not in globals():
    def get_octopusvariable(variable):
        if variable == 'ThisInstance.Server.Url':
            return os.environ['OCTOPUS_CLI_SERVER']
        elif variable == 'ThisInstance.Api.Key':
            return os.environ['OCTOPUS_CLI_API_KEY']
        elif variable == 'Octopus.Space.Id':
            return os.environ['OCTOPUS_SPACE_ID']
        elif variable == 'Octopus.Project.Name':
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
        # Octopus does not use ANSI color codes in the output, so strip these codes
        stdout_no_ansi = re.sub('\x1b\[[0-9;]*m', '', stdout)
        stderr_no_ansi = re.sub('\x1b\[[0-9;]*m', '', stderr)

        print_output(stdout_no_ansi)
        print_output(stderr_no_ansi)

    return stdout, stderr, retcode


# Variable precondition checks
if len(get_octopusvariable('ThisInstance.Server.Url')) == 0:
    print("ThisInstance.Server.Url must be defined")
    sys.exit(1)

if len(get_octopusvariable('ThisInstance.Api.Key')) == 0:
    print("ThisInstance.Api.Key must be defined")
    sys.exit(1)

print("""===================================================================================================
Octoterra is an open source tool that serializes an Octopus project to a Terraform module.
Please note that, as part of the pilot program, octoterra is not covered by existing Octopus support SLAs.
This tool is also not recommended for production deployments.
============================================================================================================
""")

print("Pulling the Docker images")
execute(['docker', 'pull', 'octopussamples/octoterra'])
execute(['docker', 'pull', 'octopusdeploy/octo'])

# Find out the IP address of the Octopus container
parsed_url = urlparse(get_octopusvariable('ThisInstance.Server.Url'))
octopus, _, _ = execute(['dig', '+short', parsed_url.hostname])

print("Octopus container hostname: " + parsed_url.hostname)
print("Octopus container IP: " + octopus.strip())

# Assume we don't ignore all changes. Exported.Project.IgnoreAllChanges can override this behaviour.
ignoreAllChanges = "false"
try:
    ignoreAllChanges = get_octopusvariable("Exported.Project.IgnoreAllChanges")
except:
    pass

# Assume a postgres backend unless ThisInstance.Terraform.Backend is set
terraformBackend = "pg"
try:
    terraformBackend = get_octopusvariable("ThisInstance.Terraform.Backend")
except:
    pass

# Assume we upload to the same space unless Octopus.UploadSpace.Id is set
uploadSpace = get_octopusvariable('Octopus.Space.Id')
try:
    uploadSpace = get_octopusvariable("Octopus.UploadSpace.Id")
except:
    pass

stdout, _, _ = execute(['docker', 'run',
                        '--rm',
                        '--add-host=' + parsed_url.hostname + ':' + octopus.strip(),
                        '-v', os.getcwd() + "/export:/export",
                        'octopussamples/octoterra',
                        # the url of the instance
                        '-url', get_octopusvariable('ThisInstance.Server.Url'),
                        # the api key used to access the instance
                        '-apiKey', get_octopusvariable('ThisInstance.Api.Key'),
                        # add a postgres backend to the generated modules
                        '-terraformBackend', terraformBackend,
                        # dump the generated HCL to the console
                        '-console',
                        # dump the project from the current space
                        '-space', get_octopusvariable('Octopus.Space.Id'),
                        # the name of the project to serialize
                        '-projectName', get_octopusvariable('Octopus.Project.Name'),
                        # ignoreProjectChanges can be set to ignore all changes to the project and variables
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
                        '-ignoreCacManagedValues=false',
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
                        # Exclude the variable that defines whether all project changes are ignored
                        '-excludeProjectVariable', 'Exported.Project.IgnoreAllChanges',
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
                        # The directory where the exported files will be saved
                        '-dest', '/export'])

print(stdout)

date = datetime.now().strftime('%Y.%m.%d.%H%M%S')


stdout, _, _ = execute(['docker', 'run',
                        '--rm',
                        '--add-host=' + parsed_url.hostname + ':' + octopus.strip(),
                        '-v', os.getcwd() + "/export:/export",
                        'octopusdeploy/octo',
                        'pack',
                        '--format', 'zip',
                        '--id', re.sub('[^0-9a-zA-Z]', '_', get_octopusvariable('Octopus.Project.Name')),
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
                        '--apiKey', get_octopusvariable('ThisInstance.Api.Key'),
                        '--server', get_octopusvariable('ThisInstance.Server.InternalUrl'),
                        '--space', uploadSpace,
                        '--package', '/export/' +
                        re.sub('[^0-9a-zA-Z]', '_', get_octopusvariable('Octopus.Project.Name')) + '.' + date + '.zip',
                        '--replace-existing'])

print(stdout)

print("##octopus[stdout-default]")

print("Done")
