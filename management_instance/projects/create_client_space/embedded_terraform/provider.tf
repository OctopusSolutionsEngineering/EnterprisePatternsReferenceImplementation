terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeploy/octopusdeploy", version = "1.3.11" }
  }

  backend "pg" {
    conn_str = "postgres://terraform:terraform@terraformdb:5432/tenant_variables?sslmode=disable"
  }
}