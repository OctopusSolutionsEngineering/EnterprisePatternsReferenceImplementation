terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.0" }
  }
}

resource "octopusdeploy_library_variable_set" "octopus_library_variable_set" {
  name = "This Instance"
  description = "Variables related to interacting with an Octopus server"
}

resource "octopusdeploy_variable" "octopus_api_key" {
  name = "ThisInstance.Api.Key"
  type = "Sensitive"
  description = "Test variable"
  is_sensitive = true
  is_editable = true
  owner_id = octopusdeploy_library_variable_set.octopus_library_variable_set.id
  sensitive_value = "API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
}