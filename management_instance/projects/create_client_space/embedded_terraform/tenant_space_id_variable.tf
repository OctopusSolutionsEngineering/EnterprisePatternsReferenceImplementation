terraform {
  backend "pg" {
    conn_str = "postgres://terraform:terraform@terraformdb:5432/tenant_variables?sslmode=disable"
  }
}

terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }
  }
}

variable "octopus_server" {
  type = string
}

variable "octopus_apikey" {
  type = string
}

provider "octopusdeploy" {
  address  = var.octopus_server
  api_key  = var.octopus_apikey
  space_id = "Spaces-1"
}

data "octopusdeploy_library_variable_sets" "octopus_server" {
  partial_name = "Octopus Server"
  skip = 0
  take = 1
}

variable "tenant" {
  type = string
}

variable "space_id" {
  type = string

  validation {
    condition     = length(var.space_id) > 7 && substr(var.space_id, 0, 7) == "Spaces-"
    error_message = "The space_id value must be a valid Space id, starting with \"Spaces-\"."
  }
}

data "octopusdeploy_tenants" "tenant" {
  skip = 0
  take = 1
  partial_name = var.tenant
}

resource "octopusdeploy_tenant_common_variable" "octopus_server" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].id
  template_id = tolist([for tmp in data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].template : tmp.id if tmp.name == "ManagedTenant.Octopus.SpaceId"])[0]
  tenant_id = data.octopusdeploy_tenants.tenant.tenants[0].id
  value = var.space_id
}