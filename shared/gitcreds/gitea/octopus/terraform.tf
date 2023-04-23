terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.0" }
  }
}

variable "cac_username" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The git username for the CaC credentials."
}

variable "cac_password" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The git password for the CaC credentials."
}

resource "octopusdeploy_git_credential" "gitcredential" {
  name     = "Git"
  type     = "UsernamePassword"
  username = var.cac_username
  password = var.cac_password
}