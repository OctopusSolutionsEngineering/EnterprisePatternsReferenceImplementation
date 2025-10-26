terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeploy/octopusdeploy", version = "1.3.11" }
  }
}

resource "octopusdeploy_project_group" "project_group_test" {
  name        = "Kubernetes"
  description = "Holds the Kubernetes projects"
}
