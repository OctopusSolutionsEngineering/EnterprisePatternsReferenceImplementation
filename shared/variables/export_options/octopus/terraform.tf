terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }
  }
}

resource "octopusdeploy_library_variable_set" "octopus_library_variable_set" {
  name = "Export Options"
  description = "Variables related to serializing and deploying upstream projects"
}

resource "octopusdeploy_variable" "octopus_api_key" {
  name         = "Exported.Project.Name"
  type         = "String"
  description  = "The name of the new project"
  is_sensitive = false
  is_editable  = true
  owner_id     = octopusdeploy_library_variable_set.octopus_library_variable_set.id
  value        = "#{Octopus.Project.Name}"

  prompt {
    description = "The name of the new project"
    label       = "Project Name"
    is_required = true
  }
}

resource "octopusdeploy_variable" "ignore_project_changes" {
  name         = "Exported.Project.IgnoreChanges"
  type         = "String"
  description  = "Select this option to ignore changes to the project once it is deployed."
  is_sensitive = false
  is_editable  = true
  owner_id     = octopusdeploy_library_variable_set.octopus_library_variable_set.id
  value        = "False"

  prompt {
    description = "Check this box to ignore changes to the deployed project"
    label       = "Ignore Project Changes"
    is_required = true
    display_settings {
      control_type = "Checkbox"
    }
  }
}

resource "octopusdeploy_variable" "ignore_project_variable_changes" {
  name         = "Exported.Project.IgnoreVariableChanges"
  type         = "String"
  description  = "Select this option to ignore changes to the project's secret variables once it is deployed (note non-secret variables are managed by CaC). This is implied by selecting the \"Ignore Project Changes\" option. "
  is_sensitive = false
  is_editable  = true
  owner_id     = octopusdeploy_library_variable_set.octopus_library_variable_set.id
  value        = "True"

  prompt {
    description = "Check this box to ignore changes to the deployed project's variables. This is also enabled by selecting the \"Ignore Project Changes\" option. "
    label       = "Ignore Project Variable Changes"
    is_required = true
    display_settings {
      control_type = "Checkbox"
    }
  }
}