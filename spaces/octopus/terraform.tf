terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.0" }
  }
}

variable "space_name" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The name of the new space"
}

resource "octopusdeploy_space" "space" {
  description                 = "A space for team ${var.space_name}."
  name                        = var.space_name
  is_default                  = false
  is_task_queue_stopped       = false
  space_managers_team_members = []
  space_managers_teams        = ["teams-everyone"]
}