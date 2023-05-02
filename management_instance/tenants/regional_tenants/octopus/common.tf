terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.0" }
  }
}

data "octopusdeploy_library_variable_sets" "variable" {
  partial_name = "This Instance"
  skip         = 0
  take         = 1
}

data "octopusdeploy_library_variable_sets" "octopus_server" {
  partial_name = "Octopus Server"
  skip = 0
  take = 1
}

data "octopusdeploy_environments" "development" {
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

data "octopusdeploy_environments" "production" {
  ids          = []
  partial_name = "Production"
  skip         = 0
  take         = 1
}

data "octopusdeploy_environments" "sync" {
  ids          = []
  partial_name = "Sync"
  skip         = 0
  take         = 1
}


data "octopusdeploy_projects" "project" {
  cloned_from_project_id = null
  ids                    = []
  is_clone               = false
  name                   = "Hello World"
  partial_name           = null
  skip                   = 0
  take                   = 1
}

data "octopusdeploy_projects" "project_cac" {
  cloned_from_project_id = null
  ids                    = []
  is_clone               = false
  name                   = "Hello World CaC"
  partial_name           = null
  skip                   = 0
  take                   = 1
}

resource "octopusdeploy_tag_set" "type" {
  name        = "tenant_type"
  description = "Tenant Type"
  sort_order  = 0
}

resource "octopusdeploy_tag" "tag_regional" {
  name        = "regional"
  color       = "#333333"
  description = "A tenant representing a region"
  sort_order  = 2
  tag_set_id = octopusdeploy_tag_set.type.id
}