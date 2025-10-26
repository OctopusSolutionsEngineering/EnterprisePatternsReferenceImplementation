terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeploy/octopusdeploy", version = "1.3.11" }
  }
}

resource "octopusdeploy_project_group" "project_group_client_space" {
  name        = "__ Client Space"
  description = "Holds the projects that create and manage client spaces"
}
