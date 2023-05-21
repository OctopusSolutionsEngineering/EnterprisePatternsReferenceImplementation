resource "octopusdeploy_environment" "environment_sync" {
  name                         = "Sync"
  description                  = ""
  allow_dynamic_infrastructure = true
  use_guided_failure           = false
  sort_order                   = 0

  jira_extension_settings {
    environment_type = "development"
  }

  jira_service_management_extension_settings {
    is_enabled = true
  }

  servicenow_extension_settings {
    is_enabled = true
  }
}

resource "octopusdeploy_lifecycle" "sync_lifecycle" {
  description = "Lifecycle used to sync projects"
  name        = "Sync"

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
    optional_deployment_targets  = [octopusdeploy_environment.environment_sync.id]
    name                         = octopusdeploy_environment.environment_sync.name

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