terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeploy/octopusdeploy", version = "1.3.11" }
  }
}

resource "octopusdeploy_tag_set" "type" {
  name        = "tenant_type"
  description = "Tenant Type"
}

resource "octopusdeploy_tag" "tag_regional" {
  name        = "regional"
  color       = "#333333"
  description = "A tenant representing a region"
  tag_set_id = octopusdeploy_tag_set.type.id
}