  octoterra \
  -url "#{ThisInstance.Server.InternalUrl}"         `# the url of the instance` \
  -apiKey "#{ThisInstance.Api.Key}"                 `# the api key used to access the instance` \
  -terraformBackend pg                              `# add a postgres backend to the generated modules` \
  -console                                          `# dump the generated HCL to the console` \
  -space "#{Octopus.Space.Id}"                      `# dump the project from the current space` \
  -projectName "#{Octopus.Project.Name}"            `# the name of the project to serialize` \
  -lookupProjectDependencies                        `# use data sources to lookup external dependencies (like environments, accounts etc) rather than serialize those external resources` \
  -defaultSecretVariableValues                      `# for any secret variables, add a default value set to the octostache value of the variable e.g. a secret variable called "database" has a default value of "#{database}"` \
  -detachProjectTemplates                           `# detach any step templates, allowing the exported project to be used in a new space` \
  -ignoreCacManagedValues                           `# CaC enabled projects will not export the deployment process, non-secret variables, and other CaC managed project settings` \
  -excludeRunbook "1. Serialize Project"            `# This is a management runbook that we do not wish to export` \
  -excludeRunbook "2. Deploy Project"               `# This is a management runbook that we do not wish to export` \
  -excludeRunbook "2. Fork and Deploy Project"      `# This is a management runbook that we do not wish to export` \
  -excludeRunbook "3. Merge Changes"                `# This is a management runbook that we do not wish to export` \
  -excludeLibraryVariableSet "Octopus Server"       `# This is library variable set used by excluded runbooks, and so we don't want to link to it in the export` \
  -excludeLibraryVariableSet "This Instance"        `# This is library variable set used by excluded runbooks, and so we don't want to link to it in the export` \
  -excludeLibraryVariableSet "Azure"                `# This is library variable set used by excluded runbooks, and so we don't want to link to it in the export` \
  -excludeProjectVariable "Exported.Project.Name"   `# This variable is only used by the management runbooks, and se we don't want to include it in the export` \
  -dest "${PWD}/export"                             `# The directory where the exported files will be saved`

date=$(date '+%Y.%m.%d.%H%M%S')
octo pack \
    --format zip \
    --id "#{Octopus.Project.Name | Replace "[^0-9a-zA-Z]" "_"}" \
    --version "${date}" \
    --basePath "${PWD}/export" \
    --outFolder "${PWD}/export"

octo push \
    --apiKey #{ThisInstance.Api.Key} \
    --server #{ThisInstance.Server.InternalUrl}\
    --space #{Octopus.Space.Id} \
    --package "/${PWD}/export/#{Octopus.Project.Name | Replace "[^0-9a-zA-Z]" "_"}.${date}.zip" \
    --replace-existing