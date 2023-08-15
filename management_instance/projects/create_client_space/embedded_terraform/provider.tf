terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.5" }
  }

  backend "pg" {
    conn_str = "postgres://terraform:terraform@terraformdb:5432/tenant_variables?sslmode=disable"
  }
}