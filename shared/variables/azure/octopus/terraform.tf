terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }
  }
}

resource "octopusdeploy_library_variable_set" "octopus_library_variable_set" {
  name = "Azure"
  description = "Variables related to interacting with Azure"

  template {
    name = "Tenant.Azure.ApplicationId"
    label = "The Azure Application ID"
    display_settings = {
      "Octopus.ControlType": "SingleLineText"
    }
  }

  template {
    name = "Tenant.Azure.SubscriptionId"
    label = "The Azure Subscription ID"
    display_settings = {
      "Octopus.ControlType": "SingleLineText"
    }
  }

  template {
    name = "Tenant.Azure.TenantId"
    label = "The Azure Tenant ID"
    display_settings = {
      "Octopus.ControlType": "SingleLineText"
    }
  }

  template {
    name = "Tenant.Azure.Password"
    label = "The Azure Password"
    display_settings = {
      "Octopus.ControlType": "Sensitive"
    }
  }
}

