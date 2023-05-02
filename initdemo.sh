#!/bin/bash

if ! which docker
then
  echo "You must install Docker"
  exit 1
fi

if ! which octo
then
  echo "You must install the Octopus client from https://octopus.com/downloads/octopuscli"
  exit 1
fi

if ! which curl
then
  echo "You must install curl"
  exit 1
fi

if ! which terraform
then
  echo "You must install terraform"
  exit 1
fi

if [[ -z "${OCTOPUS_SERVER_BASE64_LICENSE}" ]]
then
  echo "You must set the OCTOPUS_SERVER_BASE64_LICENSE environment variable to the base 64 encoded representation of an Octopus license."
  exit 1
fi

pushd docker
docker-compose up -d
popd

EXISTING=$(docker exec -it gitea su git bash -c "gitea admin user list")
USER='octopus'
if [[ "$EXISTING" == *"$USER"* ]]; then
  echo "User exists"
else
  echo "We expect to see errors here and so will retry until Gitea is started."
  max_retry=6
  counter=0
  until docker exec -it gitea su git bash -c "gitea admin user create --admin --username octopus --password Password01! --email me@example.com"
  do
     sleep 10
     [[ counter -eq $max_retry ]] && echo "Failed!" && exit 1
     echo "Trying again. Try #$counter"
     ((counter++))
  done
fi

# Now go ahead and create the orgs and repos.
curl \
  --output /dev/null \
  --silent \
  -u "octopus:Password01!" \
  -X POST \
  "http://localhost:3000/api/v1/admin/users/octopus/orgs" \
  -H "Content-Type: application/json" \
  -H "accept: application/json" \
  --data '{"username": "octopuscac"}'

curl \
  --output /dev/null \
  --silent \
  -u "octopus:Password01!" \
  -X POST \
  "http://localhost:3000/api/v1/org/octopuscac/repos" \
  -H "content-type: application/json" \
  -H "accept: application/json" \
  --data '{"name":"europe-product-service"}'

curl \
  --output /dev/null \
  --silent \
  -u "octopus:Password01!" \
  -X POST \
  "http://localhost:3000/api/v1/org/octopuscac/repos" \
  -H "content-type: application/json" \
  -H "accept: application/json" \
  --data '{"name":"europe-frontend"}'

curl \
  --output /dev/null \
  --silent \
  -u "octopus:Password01!" \
  -X POST \
  "http://localhost:3000/api/v1/org/octopuscac/repos" \
  -H "content-type: application/json" \
  -H "accept: application/json" \
  --data '{"name":"america-product-service"}'

curl \
  --output /dev/null \
  --silent \
  -u "octopus:Password01!" \
  -X POST \
  "http://localhost:3000/api/v1/org/octopuscac/repos" \
  -H "content-type: application/json" \
  -H "accept: application/json" \
  --data '{"name":"america-frontend"}'

# Wait for the Octopus server.
echo "Waiting for the Octopus server"
until $(curl --output /dev/null --silent --fail http://localhost:18080/api)
do
    printf '.'
    sleep 5
done

echo ""

# Start by creating the spaces.
docker-compose -f docker/compose.yml exec terraformdb sh -c '/usr/bin/psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE DATABASE spaces"'
pushd spaces/pgbackend
terraform init -reconfigure -upgrade
terraform apply -auto-approve
popd

# Populate the spaces with shared resources.
# Note the use of Terraform workspaces to manage the state of each space independently.
for space in Spaces-1 Spaces-2 Spaces-3
do

  docker-compose -f docker/compose.yml exec terraformdb sh -c '/usr/bin/psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE DATABASE gitcreds"'
  pushd shared/gitcreds/gitea/pgbackend
  terraform init -reconfigure -upgrade
  terraform workspace new $space
  terraform workspace select $space
  terraform apply -auto-approve -var=octopus_space_id=$space
  popd

  docker-compose -f docker/compose.yml exec terraformdb sh -c '/usr/bin/psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE DATABASE environments"'
  pushd shared/environments/dev_test_prod/pgbackend
  terraform init -reconfigure -upgrade
  terraform workspace new $space
  terraform workspace select $space
  terraform apply -auto-approve -var=octopus_space_id=$space
  popd

  docker-compose -f docker/compose.yml exec terraformdb sh -c '/usr/bin/psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE DATABASE sync_environment"'
  pushd shared/environments/sync/pgbackend
  terraform init -reconfigure -upgrade
  terraform workspace new $space
  terraform workspace select $space
  terraform apply -auto-approve -var=octopus_space_id=$space
  popd

  docker-compose -f docker/compose.yml exec terraformdb sh -c '/usr/bin/psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE DATABASE mavenfeed"'
  pushd shared/feeds/maven/pgbackend
  terraform init -reconfigure -upgrade
  terraform workspace new $space
  terraform workspace select $space
  terraform apply -auto-approve -var=octopus_space_id=$space
  popd

  docker-compose -f docker/compose.yml exec terraformdb sh -c '/usr/bin/psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE DATABASE dockerhubfeed"'
  pushd shared/feeds/dockerhub/pgbackend
  terraform init -reconfigure -upgrade
  terraform workspace new $space
  terraform workspace select $space
  terraform apply -auto-approve -var=octopus_space_id=$space
  popd

done

# Setup library variable sets
docker-compose -f docker/compose.yml exec terraformdb sh -c '/usr/bin/psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE DATABASE lib_var_octopus_server"'
pushd shared/variables/octopus_server/pgbackend
terraform init -reconfigure -upgrade
terraform workspace new "Spaces-1"
terraform workspace select "Spaces-1"
terraform apply -auto-approve -var=octopus_space_id=Spaces-1
popd

docker-compose -f docker/compose.yml exec terraformdb sh -c '/usr/bin/psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE DATABASE lib_var_this_instance"'
pushd shared/variables/this_instance/pgbackend
terraform init -reconfigure -upgrade
terraform workspace new "Spaces-1"
terraform workspace select "Spaces-1"
terraform apply -auto-approve -var=octopus_space_id=Spaces-1
popd

# Add the sample projects to the management instance
docker-compose -f docker/compose.yml exec terraformdb sh -c '/usr/bin/psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE DATABASE project_hello_world"'
pushd management_instance/projects/hello_world/pgbackend
terraform init -reconfigure -upgrade
terraform workspace new Spaces-1
terraform workspace select Spaces-1
terraform apply -auto-approve -var=octopus_space_id=Spaces-1
popd

# Add serialize and deploy runbooks to sample projects
docker-compose -f docker/compose.yml exec terraformdb sh -c '/usr/bin/psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE DATABASE serialize_and_deploy"'
pushd management_instance/runbooks/serialize_and_deploy/pgbackend
terraform init -reconfigure -upgrade
terraform workspace new "hello_world_sync_runbooks"
terraform workspace select "hello_world_sync_runbooks"
terraform apply -auto-approve -var=octopus_space_id=Spaces-1 "-var=project_name=Hello World"
popd

# Add serialize and deploy runbooks to sample projects
docker-compose -f docker/compose.yml exec terraformdb sh -c '/usr/bin/psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" -c "CREATE DATABASE management_tenants"'
pushd management_instance/tenants/regional_tenants/pgbackend
terraform init -reconfigure -upgrade
terraform workspace new Spaces-1
terraform workspace select Spaces-1
terraform apply -auto-approve -var=octopus_space_id=Spaces-1
popd

# Install all the tools we'll need to perform deployments
docker-compose -f docker/compose.yml exec octopus sh -c 'apt-get install -y jq'
docker-compose -f docker/compose.yml exec octopus sh -c 'apt update && apt install -y --no-install-recommends gnupg curl ca-certificates apt-transport-https && curl -sSfL https://apt.octopus.com/public.key | apt-key add - && sh -c "echo deb https://apt.octopus.com/ stable main > /etc/apt/sources.list.d/octopus.com.list" && apt update && apt install -y octopuscli'
docker-compose -f docker/compose.yml exec octopus sh -c 'apt-get update && apt-get install -y gnupg software-properties-common'
docker-compose -f docker/compose.yml exec octopus sh -c 'wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg'
docker-compose -f docker/compose.yml exec octopus sh -c 'echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list'
docker-compose -f docker/compose.yml exec octopus sh -c 'apt update'
docker-compose -f docker/compose.yml exec octopus sh -c 'apt-get install -y terraform'
docker-compose -f docker/compose.yml exec octopus sh -c 'curl --silent -L -o /usr/bin/octoterra https://github.com/OctopusSolutionsEngineering/OctopusTerraformExport/releases/latest/download/octoterra_linux_amd64'
docker-compose -f docker/compose.yml exec octopus sh -c 'chmod +x /usr/bin/octoterra'