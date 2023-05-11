terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }
  }
}

data "octopusdeploy_environments" "dev" {
  ids          = []
  partial_name = "Development"
  skip         = 0
  take         = 1
}

resource "octopusdeploy_lifecycle" "simple_lifecycle" {
  description = "Lifecycle including security scanning"
  name        = "Simple"

  release_retention_policy {
    quantity_to_keep    = 1
    should_keep_forever = true
    unit                = "Days"
  }

  tentacle_retention_policy {
    quantity_to_keep    = 30
    should_keep_forever = false
    unit                = "Items"
  }

  phase {
    automatic_deployment_targets = []
    optional_deployment_targets  = [data.octopusdeploy_environments.dev.environments[0].id]
    name                         = data.octopusdeploy_environments.dev.environments[0].name

    release_retention_policy {
      quantity_to_keep    = 1
      should_keep_forever = true
      unit                = "Days"
    }

    tentacle_retention_policy {
      quantity_to_keep    = 30
      should_keep_forever = false
      unit                = "Items"
    }
  }
}