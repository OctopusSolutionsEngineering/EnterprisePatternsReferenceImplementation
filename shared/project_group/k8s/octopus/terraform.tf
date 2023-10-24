terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.9" }
  }
}

resource "octopusdeploy_project_group" "project_group_test" {
  name        = "Kubernetes"
  description = "Holds the Kubernetes projects"
}
