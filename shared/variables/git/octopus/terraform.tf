resource "octopusdeploy_library_variable_set" "octopus_library_variable_set" {
  name        = "Git"
  description = "Variables related to interacting with Slack"
}

variable "git_username" {
  type    = string
  default = "dummy"
}

variable "git_password" {
  type      = string
  default   = "dummy"
  sensitive = true
}

variable "git_protocol" {
  type      = string
  default   = "http"
}

variable "git_host" {
  type      = string
  default   = "gitea:3000"
}

variable "git_organization" {
  type      = string
  default   = "octopuscac"
}

resource "octopusdeploy_variable" "git_password" {
  owner_id        = octopusdeploy_library_variable_set.octopus_library_variable_set.id
  type            = "Sensitive"
  name            = "Git.Credentials.Password"
  is_sensitive    = true
  sensitive_value = var.git_password
}

resource "octopusdeploy_variable" "git_username" {
  owner_id     = octopusdeploy_library_variable_set.octopus_library_variable_set.id
  type         = "String"
  name         = "Git.Credentials.Username"
  is_sensitive = false
  value        = var.git_username
}0

resource "octopusdeploy_variable" "git_proto" {
  owner_id     = octopusdeploy_library_variable_set.octopus_library_variable_set.id
  type         = "String"
  name         = "Git.Url.Protocol"
  is_sensitive = false
  value        = var.git_protocol
}

resource "octopusdeploy_variable" "git_host" {
  owner_id     = octopusdeploy_library_variable_set.octopus_library_variable_set.id
  type         = "String"
  name         = "Git.Url.Host"
  is_sensitive = false
  value        = var.git_host
}

resource "octopusdeploy_variable" "git_organization" {
  owner_id     = octopusdeploy_library_variable_set.octopus_library_variable_set.id
  type         = "String"
  name         = "Git.Url.Organization"
  is_sensitive = false
  value        = var.git_organization
}