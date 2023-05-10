variable "europe_azure_application_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure application ID."
}

variable "europe_azure_subscription_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure subscription ID."
}

variable "europe_azure_password" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The Azure password."
}

variable "europe_azure_tenant_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure tenant ID."
}

variable "europe_k8s_cert" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The K8s user cert."
}

variable "europe_k8s_url" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The K8s URL."
}

variable "europe_docker_username" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The Docker username."
}

variable "europe_docker_password" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Docker password"
}

resource "octopusdeploy_tenant" "europe" {
  name        = "Europe"
  description = "Tenant representing the European region Octopus space"
  tenant_tags = ["tenant_type/regional"]

  project_environment {
    environments = [data.octopusdeploy_environments.development.environments[0].id, data.octopusdeploy_environments.test.environments[0].id, data.octopusdeploy_environments.production.environments[0].id, data.octopusdeploy_environments.sync.environments[0].id]
    project_id   = data.octopusdeploy_projects.project.projects[0].id
  }

  project_environment {
    environments = [data.octopusdeploy_environments.development.environments[0].id, data.octopusdeploy_environments.test.environments[0].id, data.octopusdeploy_environments.production.environments[0].id, data.octopusdeploy_environments.sync.environments[0].id]
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

  project_environment {
    environments = [
      data.octopusdeploy_environments.sync.environments[0].id
    ]
    project_id   = data.octopusdeploy_projects.project_k8s_microservice_template.projects[0].id
  }
}

resource "octopusdeploy_tenant_common_variable" "europe_octopus_apikey" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].id
  template_id = tolist([for tmp in data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].template : tmp.id if tmp.name == "ManagedTenant.Octopus.ApiKey"])[0]
  tenant_id = octopusdeploy_tenant.europe.id
  value = "API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
}

resource "octopusdeploy_tenant_common_variable" "europe_octopus_spaceid" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].id
  template_id = tolist([for tmp in data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].template : tmp.id if tmp.name == "ManagedTenant.Octopus.Url"])[0]
  tenant_id = octopusdeploy_tenant.europe.id
  value = "http://octopus:8080"
}

resource "octopusdeploy_tenant_common_variable" "europe_azure_application_id" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].template :
    tmp.id if tmp.name == "Tenant.Azure.ApplicationId"
  ])[0]
  tenant_id               = octopusdeploy_tenant.europe.id
  value                   = var.europe_azure_application_id == "" ? var.azure_application_id : var.europe_azure_application_id
}

resource "octopusdeploy_tenant_common_variable" "europe_azure_subscription_id" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].template :
    tmp.id if tmp.name == "Tenant.Azure.SubscriptionId"
  ])[0]
  tenant_id               = octopusdeploy_tenant.europe.id
  value                   = var.europe_azure_subscription_id == "" ? var.azure_subscription_id : var.europe_azure_subscription_id
}

resource "octopusdeploy_tenant_common_variable" "europe_azure_tenant_id" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].template :
    tmp.id if tmp.name == "Tenant.Azure.TenantId"
  ])[0]
  tenant_id               = octopusdeploy_tenant.europe.id
  value                   = var.europe_azure_tenant_id== "" ? var.azure_tenant_id : var.europe_azure_tenant_id
}

resource "octopusdeploy_tenant_common_variable" "europe_azure_password" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].template :
    tmp.id if tmp.name == "Tenant.Azure.Password"
  ])[0]
  tenant_id               = octopusdeploy_tenant.europe.id
  value                   = var.europe_azure_password == "" ? var.azure_password : var.europe_azure_password
}

resource "octopusdeploy_tenant_common_variable" "europe_k8s_cert" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.k8s.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.k8s.library_variable_sets[0].template :
    tmp.id if tmp.name == "Tenant.K8S.CertificateData"
  ])[0]
  tenant_id               = octopusdeploy_tenant.europe.id
  value                   = var.europe_k8s_cert
}

resource "octopusdeploy_tenant_common_variable" "europe_k8s_url" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.k8s.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.k8s.library_variable_sets[0].template :
    tmp.id if tmp.name == "Tenant.K8S.Url"
  ])[0]
  tenant_id               = octopusdeploy_tenant.europe.id
  value                   = var.europe_k8s_url
}

resource "octopusdeploy_tenant_common_variable" "europe_docker_username" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.docker.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.docker.library_variable_sets[0].template :
    tmp.id if tmp.name == "Tenant.Docker.Username"
  ])[0]
  tenant_id               = octopusdeploy_tenant.europe.id
  value                   = var.europe_docker_username == "" ? var.docker_username : var.europe_docker_username
}

resource "octopusdeploy_tenant_common_variable" "europe_docker_password" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.docker.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.docker.library_variable_sets[0].template :
    tmp.id if tmp.name == "Tenant.Docker.Password"
  ])[0]
  tenant_id               = octopusdeploy_tenant.europe.id
  value                   = var.europe_docker_password == "" ? var.docker_password : var.europe_docker_password
}

resource "octopusdeploy_tenant_common_variable" "europe_slack_bot_token" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.slack.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.slack.library_variable_sets[0].template :
    tmp.id if tmp.name == "Slack.Bot.Token"
  ])[0]
  tenant_id               = octopusdeploy_tenant.europe.id
  value                   = var.slack_bot_token
}

resource "octopusdeploy_tenant_common_variable" "europe_slack_support_users" {
  library_variable_set_id = data.octopusdeploy_library_variable_sets.slack.library_variable_sets[0].id
  template_id             = tolist([
    for tmp in data.octopusdeploy_library_variable_sets.slack.library_variable_sets[0].template :
    tmp.id if tmp.name == "Slack.Support.Users"
  ])[0]
  tenant_id               = octopusdeploy_tenant.europe.id
  value                   = var.slack_support_users
}