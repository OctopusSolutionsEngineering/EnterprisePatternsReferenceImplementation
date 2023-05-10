terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }
  }
}

resource "octopusdeploy_library_variable_set" "octopus_library_variable_set" {
  name        = "Shared Slack"
  description = "Variables related to interacting with Slack"
}

variable "slack_bot_token" {
  type = string
}

resource "octopusdeploy_variable" "bot_token" {
  owner_id        = octopusdeploy_library_variable_set.octopus_library_variable_set.id
  type            = "Sensitive"
  name            = "Slack.Bot.Token"
  is_sensitive    = true
  sensitive_value = var.slack_bot_token
}
