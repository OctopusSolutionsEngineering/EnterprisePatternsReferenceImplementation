terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.0" }
  }
}

resource "octopusdeploy_space" "europe" {
  description                 = "A space for team Europe."
  name                        = "Europe"
  is_default                  = false
  is_task_queue_stopped       = false
  space_managers_team_members = []
  space_managers_teams        = ["teams-everyone"]
}

resource "octopusdeploy_space" "america" {
  description                 = "A space for team America."
  name                        = "America"
  is_default                  = false
  is_task_queue_stopped       = false
  space_managers_team_members = []
  space_managers_teams        = ["teams-everyone"]
}