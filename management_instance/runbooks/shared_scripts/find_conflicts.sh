echo "##octopus[stdout-verbose]"

CAC_USERNAME=${cac_username}
CAC_PASSWORD=${cac_password}
TEMPLATE_REPO=http://$${CAC_USERNAME}:$${CAC_PASSWORD}@gitea:3000/octopuscac/#{Octopus.Project.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"_\"}.git
BRANCH=main

printf 'terraform {\n
  backend "pg" {\n
  }\n
  required_providers {\n
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }\n
  }\n
}' > backend.tf

cat backend.tf

echo "Terraform init"
terraform init \
  -no-color \
  -backend-config="conn_str=postgres://terraform:terraform@terraformdb:5432/${backend}?sslmode=disable"

echo "Setting Git details"
git config --global user.email "octopus@octopus.com" 2>&1
git config --global user.name "Octopus Server" 2>&1

echo "##octopus[stdout-default]"
echo "✓ - Up to date"
echo "▶ - Can automatically merge"
echo "× - Merge conflict"
echo "##octopus[stdout-verbose]"

for i in $(terraform workspace list|sed 's/*//g'); do
    if [[ $${i} == "default" ]]; then
        continue
    fi

    terraform workspace select $${i}

    # Find the cac url
    URL=$(terraform show -json | jq -r '.values.root_module.resources[] | select(.type == "octopusdeploy_project") | .values.git_library_persistence_settings[0].url')

    echo $URL

    if [[ "$URL" != "null" ]]
    then

      mkdir "$${i}"
      pushd "$${i}"

      git clone "$${URL}" ./ 2>&1
      git remote add upstream "$${TEMPLATE_REPO}" 2>&1
      git fetch --all 2>&1
      git checkout -b "upstream-$${BRANCH}" "upstream/$${BRANCH}" 2>&1

      if [[ "$${BRANCH}" != "main" && "$${BRANCH}" != "master" ]]
      then
        git checkout -b "$${BRANCH}" "origin/$${BRANCH}" 2>&1
      else
        git checkout "$${BRANCH}" 2>&1
      fi

      # Test if the template branch needs to be merged into the project branch
      MERGE_BASE=$(git merge-base "$${BRANCH}" "upstream-$${BRANCH}")
      MERGE_SOURCE_CURRENT_COMMIT=$(git rev-parse "upstream-$${BRANCH}")

      # Test the results of a merge with the upstream branch
      git merge --no-commit --no-ff "upstream-$${BRANCH}" 2>&1
      MERGE_RESULT=$?

      popd

      echo "##octopus[stdout-default]"

      if [[ "$${MERGE_BASE}" == "$${MERGE_SOURCE_CURRENT_COMMIT}" ]]
      then
        terraform show -json | jq -r '.values.root_module.resources[] | select(.type == "octopusdeploy_project") | "\(.values.space_id): \"\(.values.name)\" \(.values.git_library_persistence_settings[0].url // "") ✓"'
      elif [[ "$${MERGE_RESULT}" != "0" ]]; then
        terraform show -json | jq -r '.values.root_module.resources[] | select(.type == "octopusdeploy_project") | "\(.values.space_id): \"\(.values.name)\" \(.values.git_library_persistence_settings[0].url // "") ×"'
      else
        terraform show -json | jq -r '.values.root_module.resources[] | select(.type == "octopusdeploy_project") | "\(.values.space_id): \"\(.values.name)\" \(.values.git_library_persistence_settings[0].url // "") ▶"'
      fi

      echo "##octopus[stdout-verbose]"
    fi
done
