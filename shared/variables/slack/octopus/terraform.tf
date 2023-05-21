resource "octopusdeploy_library_variable_set" "octopus_library_variable_set" {
  name        = "Shared Slack"
  description = "Variables related to interacting with Slack"
}

variable "slack_bot_token" {
  type    = string
  default = "dummy"
}

variable "slack_support_users" {
  type    = string
  default = "dummy"
}

resource "octopusdeploy_variable" "bot_token" {
  owner_id        = octopusdeploy_library_variable_set.octopus_library_variable_set.id
  type            = "Sensitive"
  name            = "Slack.Bot.Token"
  is_sensitive    = true
  sensitive_value = var.slack_bot_token
}

resource "octopusdeploy_variable" "support_users" {
  owner_id     = octopusdeploy_library_variable_set.octopus_library_variable_set.id
  type         = "String"
  name         = "Slack.Support.Users"
  is_sensitive = false
  value        = var.slack_support_users
}
