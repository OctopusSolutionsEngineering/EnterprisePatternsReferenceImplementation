terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }
  }
}

resource "octopusdeploy_user" "user" {
  display_name  = "Deployer"
  email_address = "deployer@example.org"
  is_active     = true
  is_service    = false
  password      = "Password01!"
  username      = "deployer"
}

resource "octopusdeploy_team" "editors" {
  name  = "Deployers"
  users = [octopusdeploy_user.user.id]
}
