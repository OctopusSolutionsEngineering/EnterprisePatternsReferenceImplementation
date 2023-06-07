import subprocess
import os
import re
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
        print_output(stdout)
        print_output(stderr)

    return stdout, stderr, retcode

print("""===================================================================================================
Octoterra is an open source tool that serializes an Octopus project to a Terraform module.
Please note that, as part of the pilot program, octoterra is not covered by existing Octopus support SLAs.
This tool is also not recommended for production deployments.
============================================================================================================
""")

print("Pulling the octoterra image")
execute(['docker', 'pull', 'octopussamples/octoterra'])

# Find out the IP address of the Octopus container
parsed_url = urlparse(get_octopusvariable('ThisInstance.Server.Url'))
octopus, _, _ = execute(['dig', '+short', parsed_url.hostname])

print("Octopus container hostname: " + parsed_url.hostname)
print("Octopus container IP: " + octopus.strip())

stdout, _, _ = execute(['docker', 'run',
                        '--rm',
                        '--add-host=octopus:' + octopus.strip(),
                        '-v', os.getcwd() + "/export:/export",
                        'octopussamples/octoterra',
                        # the url of the instance
                        '-url', get_octopusvariable('ThisInstance.Server.Url'),
                        # the api key used to access the instance
                        '-apiKey', get_octopusvariable('ThisInstance.Api.Key'),
                        # add a postgres backend to the generated modules
                        '-terraformBackend', 'pg',
                        # dump the generated HCL to the console
                        '-console',
                        # dump the project from the current space
                        '-space', get_octopusvariable('Octopus.Space.Id'),
                        # the name of the project to serialize
                        '-projectName', get_octopusvariable('Octopus.Project.Name'),
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
                        # CaC managed project settings
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
                        # The directory where the exported files will be saved
                        '-dest', '/export'])

print(stdout)

date = datetime.now().strftime('%Y.%m.%d.%H%M%S')

stdout, _, _ = execute(['octo', 'pack',
                        '--format', 'zip',
                        '--id', re.sub('[^0-9a-zA-Z]', '_', get_octopusvariable('Octopus.Project.Name')),
                        '--version', date,
                        '--basePath', os.getcwd() + '/export',
                        '--outFolder', os.getcwd() + '/export'])

print(stdout)

stdout, _, _ = execute(['octo', 'push',
                        '--apiKey', get_octopusvariable('ThisInstance.Api.Key'),
                        '--server', get_octopusvariable('ThisInstance.Server.InternalUrl'),
                        '--space', get_octopusvariable('Octopus.Space.Id'),
                        '--package', os.getcwd() + '/export/' +
                        re.sub('[^0-9a-zA-Z]', '_', get_octopusvariable('Octopus.Project.Name')) + '.' + date + '.zip',
                        '--replace-existing'])

print(stdout)

print("##octopus[stdout-default]")

print("Done")
