echo "##octopus[stdout-verbose]"

printf 'terraform {\n
  backend "pg" {\n
  }\n
  required_providers {\n
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }\n
  }\n
}' > backend.tf

cat backend.tf

terraform init \
  -no-color \
  -backend-config="conn_str=postgres://terraform:terraform@terraformdb:5432/${backend}?sslmode=disable"

for i in $(terraform workspace list|sed 's/*//g'); do
    if [[ $${i} == "default" ]]; then
        continue
    fi

    terraform workspace select $${i}

    echo "##octopus[stdout-default]"
    terraform show -json | jq -r '.values.root_module.resources[] | select(.type == "octopusdeploy_project") | .values.name'
    echo "##octopus[stdout-verbose]"
done
