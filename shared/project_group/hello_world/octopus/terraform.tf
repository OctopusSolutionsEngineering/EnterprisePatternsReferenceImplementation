terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }
  }
}

resource "octopusdeploy_project_group" "project_group_test" {
  name        = "Hello World"
  description = "Holds the simple Hello World project"
}
