#!/bin/bash

pushd docker
docker-compose up -d
popd

EXISTING=$(docker exec -it gitea su git bash -c "gitea admin user list")
USER='octopus'
if [[ "$EXISTING" == *"$USER"* ]]; then
  echo "User exists"
else
  # We expect these first few attempts to fail as Gitae is being setup by Docker.
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
pushd spaces/pgbackend
terraform init -reconfigure -upgrade
terraform apply -auto-approve
popd


# Populate the spaces with shared resources.
# Note the use of Terraform workspaces to manage the state of each space independently.
for space in Spaces-1 Spaces-2 Spaces-3
do

  pushd shared/gitcreds/gitea/pgbackend
  terraform init -reconfigure -upgrade
  terraform workspace new $space
  terraform workspace select $space
  terraform apply -auto-approve -var=octopus_space_id=$space
  popd

  pushd shared/environments/dev_test_prod/pgbackend
  terraform init -reconfigure -upgrade
  terraform workspace new $space
  terraform workspace select $space
  terraform apply -auto-approve -var=octopus_space_id=$space
  popd

  pushd shared/feeds/maven/pgbackend
  terraform init -reconfigure -upgrade
  terraform workspace new $space
  terraform workspace select $space
  terraform apply -auto-approve -var=octopus_space_id=$space
  popd

  pushd shared/feeds/dockerhub/pgbackend
  terraform init -reconfigure -upgrade
  terraform workspace new $space
  terraform workspace select $space
  terraform apply -auto-approve -var=octopus_space_id=$space
  popd

done

# Add the sample projects to the management instance

pushd management_instance/projects/hello_world/pgbackend
terraform init -reconfigure -upgrade
terraform workspace new $space
terraform workspace select $space
terraform apply -auto-approve -var=octopus_space_id=Spaces-1
popd

pushd management_instance/runbooks/serialize_and_deploy/pgbackend
terraform init -reconfigure -upgrade
terraform workspace new "Hello World"
terraform workspace select "Hello World"
terraform apply -auto-approve -var=octopus_space_id=Spaces-1 "-var=project_name=Hello World"
popd

# Setup library variable sets
pushd shared/variables/octopus_server/pgbackend
terraform init -reconfigure -upgrade
terraform workspace new "Spaces-1"
terraform workspace select "Spaces-1"
terraform apply -auto-approve -var=octopus_space_id=Spaces-1
popd

pushd shared/variables/this_instance/pgbackend
terraform init -reconfigure -upgrade
terraform workspace new "Spaces-1"
terraform workspace select "Spaces-1"
terraform apply -auto-approve -var=octopus_space_id=Spaces-1
popd

# Push some utility packages
if [[ ! -f OctopusTools.9.0.0.tar.gz ]]
then
  curl \
    --silent \
    https://download.octopusdeploy.com/octopus-tools/9.0.0/OctopusTools.9.0.0.linux-x64.tar.gz \
    --output OctopusTools.9.0.0.tar.gz
fi

octo push \
    --apiKey API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA \
    --server http://localhost:18080 \
    --space Spaces-1 \
    --package OctopusTools.9.0.0.tar.gz \
    --replace-existing