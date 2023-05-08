terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }
  }
}

resource "octopusdeploy_library_variable_set" "octopus_library_variable_set" {
  name = "Kubernetes"
  description = "Variables related to interacting with Kubernetes"

  template {
    name = "Tenant.K8S.CertificateData"
    label = "The K8S User Certificate"
    display_settings = {
      "Octopus.ControlType": "Sensitive"
    }
  }

  template {
    name = "Tenant.K8S.Url"
    label = "The K8S API Endpoint"
    display_settings = {
      "Octopus.ControlType": "SingleLineText"
    }
  }
}

