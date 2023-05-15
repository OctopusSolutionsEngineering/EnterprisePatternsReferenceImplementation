import subprocess
import sys
import os
import re
from datetime import datetime

if "get_octopusvariable" not in globals():
    print("Script must be run as an Octopus step")
    sys.exit(1)


def execute(args, cwd=None):
    process = subprocess.Popen(args,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE,
                               text=True,
                               cwd=cwd)
    stdout, stderr = process.communicate()
    retcode = process.returncode
    return stdout, stderr, retcode


print("Pulling the octoterra image")
print("##octopus[stdout-verbose]")
execute(['docker', 'pull', 'octopussamples/octoterra'])


# Find out the IP address of the Octopus container
octopus, _, _ = execute(['dig', '+short', 'octopus'])

print ("Octopus container IP: " + octopus)

stdout = execute(['docker', 'run',
         '--add-host=octopus:' + octopus,
         '-v', os.getcwd() + "/export:/export",
         'octopussamples/octoterra',
         '-url', get_octopusvariable('ThisInstance.Server.Url'),                   # the url of the instance
         '-apiKey', get_octopusvariable('ThisInstance.Api.Key'),                   # the api key used to access the instance
         '-terraformBackend', 'pg',                                                # add a postgres backend to the generated modules
         '-console',                                                               # dump the generated HCL to the console
         '-space', get_octopusvariable('Octopus.Space.Id'),                        # dump the project from the current space
         '-projectName', get_octopusvariable('Octopus.Project.Name'),              # the name of the project to serialize
         '-lookupProjectDependencies',                                             # use data sources to lookup external dependencies (like environments, accounts etc) rather than serialize those external resources
         '-defaultSecretVariableValues',                                           # for any secret variables, add a default value set to the octostache value of the variable e.g. a secret variable called "database" has a default value of "#{database}"
         '-detachProjectTemplates',                                                # detach any step templates, allowing the exported project to be used in a new space
         '-ignoreProjectGroupChanges',                                             # allow the downstream project to move between project groups
         '-ignoreProjectNameChanges',                                              # allow the downstream project to change names
         '-ignoreCacManagedValues=false',                                          # CaC enabled projects will not export the deployment process, non-secret variables, and other CaC managed project settings
         '-ignoreProjectVariableChanges',                                          # This value is always true. Either this is an unmanaged project, in which case we are never reapplying it; or is is a variable configured project, in which case we need to ignore variable changes, or it is a shared CaC project, in which case we don't use Terraform to manage variables.
         '-excludeVariableEnvironmentScopes', 'Sync',                              # To have secret variables available when applying a downstream project, they must be scoped to the Sync environment. But we do not need this scoping in the downstream project, so the Sync environment is removed from any variable scopes when serializing it to Terraform.
         '-excludeProjectVariableRegex', 'Private\\..*',                           # Exclude any variables starting with "Private."
         '-excludeRunbookRegex', '__ .*',                                          # This is a management runbook that we do not wish to export
         '-excludeLibraryVariableSet', 'Octopus Server',                           # This is library variable set used by excluded runbooks, and so we don't want to link to it in the export
         '-excludeLibraryVariableSet', 'This Instance',                            # This is library variable set used by excluded runbooks, and so we don't want to link to it in the export
         '-excludeLibraryVariableSet', 'Azure',                                    # This is library variable set used by excluded runbooks, and so we don't want to link to it in the export
         '-excludeLibraryVariableSet', 'Export Options',                           # This is library variable set used by excluded runbooks, and so we don't want to link to it in the export
         '-dest', '/export'])                                                      # The directory where the exported files will be saved

print(stdout)

date = datetime.now().strftime('%Y.%m.%d.%H%M%S')

stdout = execute(['octo', 'pack',
                  '--format', 'zip',
                  '--id', re.sub('[^0-9a-zA-Z]', '_', get_octopusvariable('Octopus.Project.Name')),
                  '--version', date,
                  '--basePath', os.getcwd() + '/export',
                  '--outFolder', os.getcwd() + '/export'])

print(stdout)

stdout = execute(['octo', 'push',
                  '--apiKey', get_octopusvariable('ThisInstance.Api.Key'),
                  '--server', get_octopusvariable('ThisInstance.Server.InternalUrl'),
                  '--space', get_octopusvariable('Octopus.Space.Id'),
                  '--package', os.getcwd() + '/export/' +
                  re.sub('[^0-9a-zA-Z]', '_', get_octopusvariable('Octopus.Project.Name')) + '.' + date + '.zip',
                  '--replace-existing'])

print(stdout)

print("##octopus[stdout-default]")

print("Done")
