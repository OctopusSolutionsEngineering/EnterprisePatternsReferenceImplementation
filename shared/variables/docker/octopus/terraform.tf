resource "octopusdeploy_library_variable_set" "octopus_library_variable_set" {
  name = "Docker"
  description = "Variables related to interacting with DockerHub"

  template {
    name = "Tenant.Docker.Username"
    label = "The Docker Username"
    display_settings = {
      "Octopus.ControlType": "SingleLineText"
    }
  }

  template {
    name = "Tenant.Docker.Password"
    label = "The Docker Password"
    display_settings = {
      "Octopus.ControlType": "Sensitive"
    }
  }
}

