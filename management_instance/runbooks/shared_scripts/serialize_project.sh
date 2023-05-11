echo "Pulling the octoterra image"
echo "##octopus[stdout-verbose]"
docker pull octopussamples/octoterra
echo "##octopus[stdout-default]"

# Find out the IP address of the Octopus container
OCTOPUS=$(dig +short octopus)

docker run \
  "--add-host=octopus:$${OCTOPUS}" \
  -v "$${PWD}/export:/export" \
  octopussamples/octoterra \
  -url "#{ThisInstance.Server.Url}"                                   `# the url of the instance` \
  -apiKey "#{ThisInstance.Api.Key}"                                         `# the api key used to access the instance` \
  -terraformBackend pg                                                      `# add a postgres backend to the generated modules` \
  -console                                                                  `# dump the generated HCL to the console` \
  -space "#{Octopus.Space.Id}"                                              `# dump the project from the current space` \
  -projectName "#{Octopus.Project.Name}"                                    `# the name of the project to serialize` \
  -lookupProjectDependencies                                                `# use data sources to lookup external dependencies (like environments, accounts etc) rather than serialize those external resources` \
  -defaultSecretVariableValues                                              `# for any secret variables, add a default value set to the octostache value of the variable e.g. a secret variable called "database" has a default value of "#{database}"` \
  -detachProjectTemplates                                                   `# detach any step templates, allowing the exported project to be used in a new space` \
  -ignoreProjectGroupChanges                                                `# allow the downstream project to move between project groups` \
  -ignoreProjectNameChanges                                                 `# allow the downstream project to change names` \
  -ignoreCacManagedValues=false                                             `# CaC enabled projects will not export the deployment process, non-secret variables, and other CaC managed project settings` \
  -ignoreProjectVariableChanges                                             `# This value is always true. Either this is an unmanaged project, in which case we are never reapplying it; or is is a variable configured project, in which case we need to ignore variable changes, or it is a shared CaC project, in which case we don't use Terraform to manage variables. ` \
  -excludeProjectVariablesRegex "Private\..*"                               `# Exclude any variables starting with "Private."` \
  -excludeRunbook "__ 1. Serialize Project"                                 `# This is a management runbook that we do not wish to export` \
  -excludeRunbook "__ 2. Deploy Project"                                    `# This is a management runbook that we do not wish to export` \
  -excludeRunbook "__ 2. Fork and Deploy Project"                           `# This is a management runbook that we do not wish to export` \
  -excludeRunbook "__ 3. Merge with Downstream Project"                     `# This is a management runbook that we do not wish to export` \
  -excludeRunbook "__ 4. List Downstream Projects"                          `# This is a management runbook that we do not wish to export` \
  -excludeRunbook "__ 4. List Downstream Projects"                          `# This is a management runbook that we do not wish to export` \
  -excludeRunbook "__ 5. Find Updates"                                      `# This is a management runbook that we do not wish to export` \
  -excludeLibraryVariableSet "Octopus Server"                               `# This is library variable set used by excluded runbooks, and so we don't want to link to it in the export` \
  -excludeLibraryVariableSet "This Instance"                                `# This is library variable set used by excluded runbooks, and so we don't want to link to it in the export` \
  -excludeLibraryVariableSet "Azure"                                        `# This is library variable set used by excluded runbooks, and so we don't want to link to it in the export` \
  -excludeLibraryVariableSet "Export Options"                               `# This is library variable set used by excluded runbooks, and so we don't want to link to it in the export` \
  -dest "/export"                                                           `# The directory where the exported files will be saved`

date=$(date '+%Y.%m.%d.%H%M%S')
octo pack \
    --format zip \
    --id "#{Octopus.Project.Name | Replace "[^0-9a-zA-Z]" "_"}" \
    --version "$${date}" \
    --basePath "$${PWD}/export" \
    --outFolder "$${PWD}/export"

octo push \
    --apiKey #{ThisInstance.Api.Key} \
    --server #{ThisInstance.Server.InternalUrl}\
    --space #{Octopus.Space.Id} \
    --package "/$${PWD}/export/#{Octopus.Project.Name | Replace "[^0-9a-zA-Z]" "_"}.$${date}.zip" \
    --replace-existing