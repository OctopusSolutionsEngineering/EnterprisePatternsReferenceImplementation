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

variable "america_k8s_cert" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The K8s user cert."
}

variable "america_k8s_url" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The K8s URL."
}

variable "america_docker_username" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The DOcker username."
}

variable "america_docker_password" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Docker password"
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

  project_environment {
    environments = [
      data.octopusdeploy_environments.sync.environments[0].id
    ]
    project_id   = data.octopusdeploy_projects.project_init_space_k8s.projects[0].id
  }

  project_environment {
    environments = [
      data.octopusdeploy_environments.sync.environments[0].id
    ]
    project_id   = data.octopusdeploy_projects.project_create_client_space.projects[0].id
  }
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
    tmp.id if tmp.name == "ManagedTenant.Octopus.Url"
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

resource "octopusdeploy_tenant_common_variable" "america_k8s_cert" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.k8s.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.k8s.library_variable_sets[0].template :
    tmp.id if tmp.name == "Tenant.K8S.CertificateData"
  ])[0]
  tenant_id               = octopusdeploy_tenant.america.id
  value                   = var.america_k8s_cert
  depends_on              = [octopusdeploy_tenant.america]
}

resource "octopusdeploy_tenant_common_variable" "america_k8s_url" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.k8s.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.k8s.library_variable_sets[0].template :
    tmp.id if tmp.name == "Tenant.K8S.Url"
  ])[0]
  tenant_id               = octopusdeploy_tenant.america.id
  value                   = var.america_k8s_url
  depends_on              = [octopusdeploy_tenant.america]
}

resource "octopusdeploy_tenant_common_variable" "america_docker_username" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.docker.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.docker.library_variable_sets[0].template :
    tmp.id if tmp.name == "Tenant.Docker.Username"
  ])[0]
  tenant_id               = octopusdeploy_tenant.america.id
  value                   = var.america_docker_username
  depends_on              = [octopusdeploy_tenant.america]
}

resource "octopusdeploy_tenant_common_variable" "america_docker_password" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.docker.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.docker.library_variable_sets[0].template :
    tmp.id if tmp.name == "Tenant.Docker.Password"
  ])[0]
  tenant_id               = octopusdeploy_tenant.america.id
  value                   = var.america_docker_password
  depends_on              = [octopusdeploy_tenant.america]
}
