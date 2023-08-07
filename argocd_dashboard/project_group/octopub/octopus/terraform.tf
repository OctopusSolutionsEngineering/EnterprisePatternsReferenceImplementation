terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.4" }
  }
}

resource "octopusdeploy_project_group" "project_group_client_space" {
  name        = "Octopub"
  description = "Manages the deployment of Octopus in ArgoCD"
}
