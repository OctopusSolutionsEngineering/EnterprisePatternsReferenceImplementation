echo "##octopus[stdout-verbose]"
docker pull octopussamples/octoterra
echo "##octopus[stdout-default]"

docker run \
  --network=docker_octopus \
  -v "${PWD}:${PWD}" \
  octopussamples/octoterra \
  -url #{ThisInstance.Server.DockerUrl} \
  -apiKey #{ThisInstance.Api.Key} \
  -terraformBackend pg \
  -console \
  -space "#{Octopus.Space.Id}" \
  -projectName "#{Octopus.Project.Name}" \
  -lookupProjectDependencies \
  -defaultSecretVariableValues \
  -detachProjectTemplates \
  -excludeRunbook "Serialize Project" \
  -excludeRunbook "Deploy Project" \
  -dest "${PWD}/export"

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