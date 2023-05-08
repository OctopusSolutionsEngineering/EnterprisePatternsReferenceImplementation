terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }
  }
}

resource "octopusdeploy_library_variable_set" "octopus_library_variable_set" {
  name        = "Octopus Server"
  description = "Exposes templates that tenants must populate to indicate how to reach the server and space they are hosted on."

  template {
    name             = "ManagedTenant.Octopus.Server"
    label            = "The Octopus Server URL"
    display_settings = {
      "Octopus.ControlType" : "SingleLineText"
    }
  }

  template {
    name             = "ManagedTenant.Octopus.ApiKey"
    label            = "The Octopus Server API Key"
    display_settings = {
      "Octopus.ControlType" : "Sensitive"
    }
  }

  template {
    name             = "ManagedTenant.Octopus.SpaceId"
    label            = "The Octopus Server Space ID"
    display_settings = {
      "Octopus.ControlType" : "SingleLineText"
    }
    default_value = "Unknown"
  }
}

