terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }
  }
}

resource "octopusdeploy_library_variable_set" "octopus_library_variable_set" {
  name        = "Client Slack"
  description = "Variables related to interacting with Slack"
}

variable "bot_token" {
  type = string
}

resource "octopusdeploy_variable" "bot_token" {
  owner_id        = octopusdeploy_library_variable_set.octopus_library_variable_set.id
  type            = "String"
  name            = "Slack.Bot.Token"
  is_sensitive    = true
  sensitive_value = var.bot_token
}
