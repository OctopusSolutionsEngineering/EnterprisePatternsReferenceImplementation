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

  template {
    name = "Slack.Support.Users"
    label = "A comma seperated list of Slack user IDs representing those that are invited to incident channels"
    display_settings = {
      "Octopus.ControlType": "SingleLineText"
    }
  }
}

