
resource "octopusdeploy_tenant" "europe" {
  name        = "Europe"
  description = "Tenant representing the European region Octopus space"
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

data "octopusdeploy_spaces" "europe_space" {
  ids          = []
  partial_name = "Europe"
  skip         = 0
  take         = 1
}

resource "octopusdeploy_tenant_common_variable" "europe_octopus_server" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].id
  template_id = tolist([for tmp in data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].template : tmp.id if tmp.name == "ManagedTenant.Octopus.SpaceId"])[0]
  tenant_id = octopusdeploy_tenant.europe.id
  value = data.octopusdeploy_spaces.europe_space.spaces[0].id
  depends_on = [octopusdeploy_tenant.europe]
}

resource "octopusdeploy_tenant_common_variable" "europe_octopus_apikey" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].id
  template_id = tolist([for tmp in data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].template : tmp.id if tmp.name == "ManagedTenant.Octopus.ApiKey"])[0]
  tenant_id = octopusdeploy_tenant.europe.id
  value = "API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  depends_on = [octopusdeploy_tenant.europe]
}

resource "octopusdeploy_tenant_common_variable" "europe_octopus_spaceid" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].id
  template_id = tolist([for tmp in data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].template : tmp.id if tmp.name == "ManagedTenant.Octopus.Server"])[0]
  tenant_id = octopusdeploy_tenant.europe.id
  value = "http://octopus:8080"
  depends_on = [octopusdeploy_tenant.europe]
}
