data "octopusdeploy_teams" "deployers" {
  partial_name = "Deployers"
  take         = 1
  skip         = 0
}

data "octopusdeploy_user_roles" "viewer" {
  partial_name = "Read-Only"
  skip         = 0
  take         = 1
}

data "octopusdeploy_user_roles" "task_cancel" {
  partial_name = "Task Cancel"
  skip         = 0
  take         = 1
}

variable "octopus_space_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The ID of the Octopus space to populate."

  validation {
    condition     = length(var.octopus_space_id) > 7 && substr(var.octopus_space_id, 0, 7) == "Spaces-"
    error_message = "The space_id value must be a valid Space id, starting with \"Spaces-\"."
  }
}

resource "octopusdeploy_scoped_user_role" "viewer" {
  space_id     = var.octopus_space_id
  team_id      = data.octopusdeploy_teams.deployers.teams[0].id
  user_role_id = data.octopusdeploy_user_roles.viewer.user_roles[0].id
}

resource "octopusdeploy_scoped_user_role" "task_cancel" {
  space_id     = var.octopus_space_id
  team_id      = data.octopusdeploy_teams.deployers.teams[0].id
  user_role_id = data.octopusdeploy_user_roles.task_cancel.user_roles[0].id
}

resource "octopusdeploy_scoped_user_role" "release" {
  space_id     = var.octopus_space_id
  team_id      = data.octopusdeploy_teams.deployers.teams[0].id
  user_role_id = "userroles-releasecreator"
}

resource "octopusdeploy_scoped_user_role" "deploy" {
  space_id     = var.octopus_space_id
  team_id      = data.octopusdeploy_teams.deployers.teams[0].id
  user_role_id = "userroles-deploymentcreator"
}