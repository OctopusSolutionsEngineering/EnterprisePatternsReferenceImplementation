resource "octopusdeploy_environment" "environment_admin" {
  name                         = "Administration"
  description                  = ""
  allow_dynamic_infrastructure = true
  use_guided_failure           = false
  sort_order                   = 0

  jira_extension_settings {
    environment_type = "production"
  }

  jira_service_management_extension_settings {
    is_enabled = true
  }

  servicenow_extension_settings {
    is_enabled = true
  }
}

resource "octopusdeploy_lifecycle" "admin_lifecycle" {
  description = "Lifecycle used to administrate projects"
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
    optional_deployment_targets  = [octopusdeploy_environment.environment_admin.id]
    name                         = octopusdeploy_environment.environment_admin.name

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