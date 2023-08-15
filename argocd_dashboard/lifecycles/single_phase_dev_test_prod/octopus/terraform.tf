data "octopusdeploy_environments" "dev" {
  ids          = []
  partial_name = "Development"
  skip         = 0
  take         = 1
}

data "octopusdeploy_environments" "test" {
  ids          = []
  partial_name = "Test"
  skip         = 0
  take         = 1
}

data "octopusdeploy_environments" "prod" {
  ids          = []
  partial_name = "Prod"
  skip         = 0
  take         = 1
}

resource "octopusdeploy_lifecycle" "devsecops_lifecycle" {
  description = "A single phase lifecycle"
  name        = "ArgoCD Overview"

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
    optional_deployment_targets  = [
      data.octopusdeploy_environments.dev.environments[0].id,
      data.octopusdeploy_environments.test.environments[0].id,
      data.octopusdeploy_environments.prod.environments[0].id,
    ]
    name                         = "All Environments"

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