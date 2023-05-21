resource "octopusdeploy_library_variable_set" "octopus_library_variable_set" {
  name = "Export Options"
  description = "Variables related to serializing and deploying upstream projects"
}

resource "octopusdeploy_variable" "project_name" {
  name         = "Exported.Project.Name"
  type         = "String"
  description  = "The name of the new project. This is only used by the \"Deploy Project\" and \"Fork and Deploy Project\" runbooks."
  is_sensitive = false
  is_editable  = true
  owner_id     = octopusdeploy_library_variable_set.octopus_library_variable_set.id
  value        = "#{Octopus.Project.Name}"

  prompt {
    description = "The name of the new project. This is only used by the \"Deploy Project\" and \"Fork and Deploy Project\" runbooks."
    label       = "Project Name"
    is_required = true
  }
}