terraform {
  backend "pg" {
    conn_str = "postgres://terraform:terraform@localhost:15432/gitcreds?sslmode=disable"
  }
}

terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.0" }
  }
}

provider "octopusdeploy" {
  address  = "http://localhost:18080"
  api_key  = "API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  space_id = "Spaces-1"
}

module "octopus" {
  source       = "../octopus"
  cac_username = "octopus"
  cac_password = "Password01!"
}