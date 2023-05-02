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

resource "octopusdeploy_tenant" "america" {
  name        = "America"
  description = "Tenant representing the American region"
  tenant_tags = ["tenant_type/regional"]
  depends_on = [octopusdeploy_tag.tag_regional]

  project_environment {
    environments = [data.octopusdeploy_environments.development.environments[0].id, data.octopusdeploy_environments.test.environments[0].id, data.octopusdeploy_environments.production.environments[0].id, data.octopusdeploy_environments.sync.environments[0].id]
    project_id   = data.octopusdeploy_projects.project.projects[0].id
  }

  project_environment {
    environments = [data.octopusdeploy_environments.development.environments[0].id, data.octopusdeploy_environments.test.environments[0].id, data.octopusdeploy_environments.production.environments[0].id, data.octopusdeploy_environments.sync.environments[0].id]
    project_id   = data.octopusdeploy_projects.project_cac.projects[0].id
  }
}

resource "octopusdeploy_tenant" "europe" {
  name        = "Europe"
  description = "Tenant representing the European region"
  tenant_tags = ["tenant_type/regional"]
  depends_on = [octopusdeploy_tag.tag_regional]

  project_environment {
    environments = [data.octopusdeploy_environments.development.environments[0].id, data.octopusdeploy_environments.test.environments[0].id, data.octopusdeploy_environments.production.environments[0].id, data.octopusdeploy_environments.sync.environments[0].id]
    project_id   = data.octopusdeploy_projects.project.projects[0].id
  }

  project_environment {
    environments = [data.octopusdeploy_environments.development.environments[0].id, data.octopusdeploy_environments.test.environments[0].id, data.octopusdeploy_environments.production.environments[0].id, data.octopusdeploy_environments.sync.environments[0].id]
    project_id   = data.octopusdeploy_projects.project_cac.projects[0].id
  }
}