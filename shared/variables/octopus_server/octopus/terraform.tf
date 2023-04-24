terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.0" }
  }
}

resource "octopusdeploy_library_variable_set" "octopus_library_variable_set" {
  name = "Octopus Server"
  description = "Variables related to interacting with an Octopus server"

  template {
    name = "ManagedTenant.Octopus.Server"
    label = "The Octopus Server URL"
    display_settings = {
      "Octopus.ControlType": "SingleLineText"
    }
  }

  template {
    name = "ManagedTenant.Octopus.ApiKey"
    label = "The Octopus Server API Key"
    display_settings = {
      "Octopus.ControlType": "Sensitive"
    }
  }

  template {
    name = "ManagedTenant.Octopus.SpaceId"
    label = "The Octopus Server Space ID"
    display_settings = {
      "Octopus.ControlType": "SingleLineText"
    }
  }
}

