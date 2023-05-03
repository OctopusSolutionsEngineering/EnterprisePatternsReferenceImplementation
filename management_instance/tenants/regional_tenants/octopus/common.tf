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

data "octopusdeploy_library_variable_sets" "azure" {
  partial_name = "Azure"
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

data "octopusdeploy_projects" "project_init_space" {
  cloned_from_project_id = null
  ids                    = []
  is_clone               = false
  name                   = "__ Initialize Space for Azure"
  partial_name           = null
  skip                   = 0
  take                   = 1
}

data "octopusdeploy_projects" "project_web_app_cac" {
  cloned_from_project_id = null
  ids                    = []
  is_clone               = false
  name                   = "Azure Web App CaC"
  partial_name           = null
  skip                   = 0
  take                   = 1
}