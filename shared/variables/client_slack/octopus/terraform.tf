terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }
  }
}

resource "octopusdeploy_library_variable_set" "octopus_library_variable_set" {
  name = "Client Slack"
  description = "Variables related to interacting with Slack"

  template {
    name = "Slack.Bot.Token"
    label = "The Slack Bot Token"
    display_settings = {
      "Octopus.ControlType": "Sensitive"
    }
  }
}

