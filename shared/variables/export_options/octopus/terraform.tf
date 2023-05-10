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
  description  = "The name of the new project. This is only used by the \"Deploy Project\" and \"Fork and Deploy Project\" runbooks."
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