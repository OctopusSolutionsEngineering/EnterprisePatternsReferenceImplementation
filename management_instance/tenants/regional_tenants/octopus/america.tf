variable "america_azure_application_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure application ID."
}

variable "america_azure_subscription_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure subscription ID."
}

variable "america_azure_password" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The Azure password."
}

variable "america_azure_tenant_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure tenant ID."
}

resource "octopusdeploy_tenant" "america" {
  name        = "America"
  description = "Tenant representing the American region Octopus space"
  tenant_tags = ["tenant_type/regional"]

  project_environment {
    environments = [
      data.octopusdeploy_environments.development.environments[0].id,
      data.octopusdeploy_environments.test.environments[0].id,
      data.octopusdeploy_environments.production.environments[0].id,
      data.octopusdeploy_environments.sync.environments[0].id
    ]
    project_id   = data.octopusdeploy_projects.project.projects[0].id
  }

  project_environment {
    environments = [
      data.octopusdeploy_environments.development.environments[0].id,
      data.octopusdeploy_environments.test.environments[0].id,
      data.octopusdeploy_environments.production.environments[0].id,
      data.octopusdeploy_environments.sync.environments[0].id
    ]
    project_id   = data.octopusdeploy_projects.project_cac.projects[0].id
  }

  project_environment {
    environments = [
      data.octopusdeploy_environments.development.environments[0].id,
      data.octopusdeploy_environments.test.environments[0].id,
      data.octopusdeploy_environments.production.environments[0].id,
      data.octopusdeploy_environments.sync.environments[0].id
    ]
    project_id   = data.octopusdeploy_projects.project_web_app_cac.projects[0].id
  }

  project_environment {
    environments = [
      data.octopusdeploy_environments.sync.environments[0].id
    ]
    project_id   = data.octopusdeploy_projects.project_init_space.projects[0].id
  }
}

data "octopusdeploy_spaces" "america_space" {
  ids          = []
  partial_name = "America"
  skip         = 0
  take         = 1
}

resource "octopusdeploy_tenant_common_variable" "america_octopus_server" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].template :
    tmp.id if tmp.name == "ManagedTenant.Octopus.SpaceId"
  ])[0]
  tenant_id               = octopusdeploy_tenant.america.id
  value                   = data.octopusdeploy_spaces.america_space.spaces[0].id
  depends_on              = [octopusdeploy_tenant.america]
}

resource "octopusdeploy_tenant_common_variable" "america_octopus_apikey" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].template :
    tmp.id if tmp.name == "ManagedTenant.Octopus.ApiKey"
  ])[0]
  tenant_id               = octopusdeploy_tenant.america.id
  value                   = "API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  depends_on              = [octopusdeploy_tenant.america]
}

resource "octopusdeploy_tenant_common_variable" "america_octopus_spaceid" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].template :
    tmp.id if tmp.name == "ManagedTenant.Octopus.Server"
  ])[0]
  tenant_id               = octopusdeploy_tenant.america.id
  value                   = "http://octopus:8080"
  depends_on              = [octopusdeploy_tenant.america]
}

resource "octopusdeploy_tenant_common_variable" "america_azure_application_id" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].template :
    tmp.id if tmp.name == "Tenant.Azure.ApplicationId"
  ])[0]
  tenant_id               = octopusdeploy_tenant.america.id
  value                   = var.america_azure_application_id
  depends_on              = [octopusdeploy_tenant.america]
}

resource "octopusdeploy_tenant_common_variable" "america_azure_subscription_id" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].template :
    tmp.id if tmp.name == "Tenant.Azure.SubscriptionId"
  ])[0]
  tenant_id               = octopusdeploy_tenant.america.id
  value                   = var.america_azure_subscription_id
  depends_on              = [octopusdeploy_tenant.america]
}

resource "octopusdeploy_tenant_common_variable" "america_azure_tenant_id" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].template :
    tmp.id if tmp.name == "Tenant.Azure.TenantId"
  ])[0]
  tenant_id               = octopusdeploy_tenant.america.id
  value                   = var.america_azure_tenant_id
  depends_on              = [octopusdeploy_tenant.america]
}

resource "octopusdeploy_tenant_common_variable" "america_azure_password" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].template :
    tmp.id if tmp.name == "Tenant.Azure.Password"
  ])[0]
  tenant_id               = octopusdeploy_tenant.america.id
  value                   = var.america_azure_password
  depends_on              = [octopusdeploy_tenant.america]
}