
resource "octopusdeploy_variable" "argocd_environment_progression_env_metadata" {
  owner_id    = octopusdeploy_project.project_environment_progression.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[argocd/octopub-frontend-development].Environment"
  value       = "Development"
  description = "This variable links this project's Development environment to the octopub-frontend-development ArgoCD application in the argocd namespace"
}

resource "octopusdeploy_variable" "argocd_environment_progression_version_metadata" {
  owner_id    = octopusdeploy_project.project_environment_progression.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[argocd/octopub-frontend-development].ImageForReleaseVersion"
  value       = "octopussamples/octopub-frontend"
  description = "This variable indicates that the octopussamples/octopub-frontend-microservice images deployed by the ArgoCD application is used to build the Octopus release numbers"
}

resource "octopusdeploy_variable" "argocd_environment_progression_git_url" {
  owner_id    = octopusdeploy_project.project_environment_progression.id
  type        = "String"
  name        = "Template.Git.Repo.Url"
  value       = "http://gitea:3000/octopuscac/argo_cd.git"
  description = "The git URL repo"
}

resource "octopusdeploy_variable" "argocd_environment_progression_git_username" {
  owner_id    = octopusdeploy_project.project_environment_progression.id
  type        = "String"
  name        = "Template.Git.User.Name"
  value       = "octopus"
  description = "The git username"
}

resource "octopusdeploy_variable" "argocd_environment_progression_git_password" {
  owner_id        = octopusdeploy_project.project_environment_progression.id
  type            = "Sensitive"
  name            = "Template.Git.User.Password"
  is_sensitive    = true
  sensitive_value = "Password01!"
  description     = "The git password"
}

resource "octopusdeploy_variable" "argocd_environment_progression_git_sourceitems" {
  owner_id    = octopusdeploy_project.project_environment_progression.id
  type        = "String"
  name        = "Template.Git.Source.Path"
  value       = "/argocd/octopub-frontend/overlays/development/frontend-versions.yaml"
  description = "The file that represents the release settings to be promoted between environments"
}

resource "octopusdeploy_variable" "argocd_environment_progression_git_destinationpath" {
  owner_id    = octopusdeploy_project.project_environment_progression.id
  type        = "String"
  name        = "Template.Git.Destination.Path"
  value       = "/argocd/octopub-frontend/overlays/#{Octopus.Environment.Name | ToLower}"
  description = "The directory that represents the release settings in the target environment"
}

resource "octopusdeploy_variable" "argocd_environment_progression_git_source_tag" {
  owner_id    = octopusdeploy_project.project_environment_progression.id
  type        = "String"
  name        = "Template.Git.Tag"
  value       = "#{Octopus.Release.Number}"
  description = "The tag to source the environment files from"
}

resource "octopusdeploy_project" "project_environment_progression" {
  name                                 = "Progression: Octopub Frontend"
  description                          = "This project is used to manage the deployment of the Octopub Frontend via ArgoCD."
  auto_create_release                  = false
  default_guided_failure_mode          = "EnvironmentDefault"
  default_to_skip_if_already_installed = false
  discrete_channel_release             = false
  is_disabled                          = false
  is_version_controlled                = false
  lifecycle_id                         = data.octopusdeploy_lifecycles.lifecycle_simple.lifecycles[0].id
  project_group_id                     = data.octopusdeploy_project_groups.project_group_environment_progression.project_groups[0].id
  included_library_variable_sets       = []
  tenanted_deployment_participation    = "Untenanted"

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }
}

resource "octopusdeploy_deployment_process" "deployment_process_project_environment_progression" {
  project_id = octopusdeploy_project.project_environment_progression.id

  step {
    condition           = "Success"
    name                = "Tag the release"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "Tag the release"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = false
      worker_pool_id                     = data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id
      properties                         = {
        "Octopus.Action.RunOnServer"         = "true"
        "Octopus.Action.Script.ScriptSource" = "Inline"
        "Octopus.Action.Script.Syntax"       = "PowerShell"
        "Octopus.Action.Script.ScriptBody"   = file("${path.module}/Tag-Release.ps1")
      }
      environments          = [data.octopusdeploy_environments.development.environments[0].id]
      excluded_environments = []
      channels              = []
      tenant_tags           = []
      features              = []
    }

    properties   = {}
    target_roles = []
  }

  step {
    condition           = "Success"
    name                = "Promote the release"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "Promote the release"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = false
      worker_pool_id                     = data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id
      properties                         = {
        "Octopus.Action.RunOnServer"         = "true"
        "Octopus.Action.Script.ScriptSource" = "Inline"
        "Octopus.Action.Script.Syntax"       = "PowerShell"
        "Octopus.Action.Script.ScriptBody"   = file("${path.module}/Copy-Git-Files.ps1")
      }
      environments          = []
      excluded_environments = [data.octopusdeploy_environments.development.environments[0].id]
      channels              = []
      tenant_tags           = []
      features              = []
    }

    properties   = {}
    target_roles = []
  }
}