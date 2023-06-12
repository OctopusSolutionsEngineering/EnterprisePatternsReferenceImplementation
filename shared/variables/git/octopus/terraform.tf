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
  sensitive = false
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
}
