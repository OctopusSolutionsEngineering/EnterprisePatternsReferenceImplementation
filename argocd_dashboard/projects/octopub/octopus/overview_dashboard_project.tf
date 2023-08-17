data "octopusdeploy_feeds" "maven" {
  feed_type    = "Maven"
  partial_name = "Sales Maven Feed"
  skip         = 0
  take         = 1
}

resource "octopusdeploy_variable" "argocd_overview_dashboard_dev_env_metadata" {
  owner_id    = octopusdeploy_project.project_overview_dashboard.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[argocd/octopub-frontend-development].Environment"
  value       = "Development"
  description = "This variable links this project's Development environment to the octopub-frontend-development ArgoCD application in the argocd namespace"
}

resource "octopusdeploy_variable" "argocd_overview_dashboard_dev_version_metadata" {
  owner_id    = octopusdeploy_project.project_overview_dashboard.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[argocd/octopub-frontend-development].ImageForReleaseVersion"
  value       = "octopussamples/octopub-frontend"
  description = "This variable indicates that the octopussamples/octopub-frontend-microservice images deployed by the ArgoCD application is used to build the Octopus release numbers"
}

resource "octopusdeploy_variable" "argocd_overview_dashboard_test_env_metadata" {
  owner_id    = octopusdeploy_project.project_overview_dashboard.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[argocd/octopub-frontend-test].Environment"
  value       = "Test"
  description = "This variable links this project's Test environment to the octopub-frontend-test ArgoCD application in the argocd namespace"
}

resource "octopusdeploy_variable" "argocd_overview_dashboard_test_version_metadata" {
  owner_id    = octopusdeploy_project.project_overview_dashboard.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[argocd/octopub-frontend-test].ImageForReleaseVersion"
  value       = "octopussamples/octopub-frontend"
  description = "This variable indicates that the octopussamples/octopub-frontend-microservice images deployed by the ArgoCD application is used to build the Octopus release numbers"
}

resource "octopusdeploy_variable" "argocd_overview_dashboard_prod_env_metadata" {
  owner_id    = octopusdeploy_project.project_overview_dashboard.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[argocd/octopub-frontend-production].Environment"
  value       = "Production"
  description = "This variable links this project's Test environment to the octopub-frontend-prod ArgoCD application in the argocd namespace"
}

resource "octopusdeploy_variable" "argocd_overview_dashboard_prod_version_metadata" {
  owner_id    = octopusdeploy_project.project_overview_dashboard.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[argocd/octopub-frontend-production].ImageForReleaseVersion"
  value       = "octopussamples/octopub-frontend"
  description = "This variable indicates that the octopussamples/octopub-frontend-microservice images deployed by the ArgoCD application is used to build the Octopus release numbers"
}

resource "octopusdeploy_variable" "argocd_overview_dashboard_prod_package_version_metadata" {
  owner_id    = octopusdeploy_project.project_overview_dashboard.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[argocd/octopub-frontend-production].ImageForPackageVersion[Check for Vulnerabilities:sbom]"
  value       = "octopussamples/octopub-frontend"
  description = "This variable indicates that the octopussamples/octopub-frontend-microservice images deployed by the ArgoCD application is used to build the Octopus release numbers"
}

resource "octopusdeploy_variable" "argocd_overview_dashboard_test_package_version_metadata" {
  owner_id    = octopusdeploy_project.project_overview_dashboard.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[argocd/octopub-frontend-test].ImageForPackageVersion[Check for Vulnerabilities:sbom]"
  value       = "octopussamples/octopub-frontend"
  description = "This variable indicates that the octopussamples/octopub-frontend-microservice images deployed by the ArgoCD application is used to build the Octopus release numbers"
}

resource "octopusdeploy_variable" "argocd_overview_dashboard_dev_package_version_metadata" {
  owner_id    = octopusdeploy_project.project_overview_dashboard.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[argocd/octopub-frontend-development].ImageForPackageVersion[Check for Vulnerabilities:sbom]"
  value       = "octopussamples/octopub-frontend"
  description = "This variable indicates that the octopussamples/octopub-frontend-microservice images deployed by the ArgoCD application is used to build the Octopus release numbers"
}

resource "octopusdeploy_project" "project_overview_dashboard" {
  name                                 = "Overview: Octopub Frontend"
  description                          = "This project is used to manage the deployment of the Octopub Frontend via ArgoCD."
  auto_create_release                  = false
  default_guided_failure_mode          = "EnvironmentDefault"
  default_to_skip_if_already_installed = false
  discrete_channel_release             = false
  is_disabled                          = false
  is_version_controlled                = false
  lifecycle_id                         = data.octopusdeploy_lifecycles.argocd.lifecycles[0].id
  project_group_id                     = data.octopusdeploy_project_groups.project_group_overview_dashboard.project_groups[0].id
  included_library_variable_sets       = []
  tenanted_deployment_participation    = "Untenanted"

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }
}

resource "octopusdeploy_deployment_process" "deployment_process_project_octopub" {
  project_id = octopusdeploy_project.project_overview_dashboard.id

  step {
    condition           = "Success"
    name                = "Integration Tests"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "Integration Tests"
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
        "Octopus.Action.Script.ScriptBody"   = "echo \"Integration tests can be run after a deployment has succeeded.\""
      }
      environments          = []
      excluded_environments = []
      channels              = []
      tenant_tags           = []
      features              = []
    }

    properties   = {}
    target_roles = []
  }

  step {
    condition            = "Variable"
    name                 = "Check for Vulnerabilities"
    package_requirement  = "LetOctopusDecide"
    start_trigger        = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "Check for Vulnerabilities"
      notes                              = "Scan the SBOM associated with the release."
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = true
      is_required                        = true
      worker_pool_id                     = data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id
      properties                         = {
        "Octopus.Action.SubstituteInFiles.Enabled" = "True"
        "Octopus.Action.Script.ScriptBody"         = file("../scripts/vulnerability_scan.sh")
        "Octopus.Action.Script.ScriptSource"       = "Inline"
        "Octopus.Action.Script.Syntax"             = "Bash"
      }
      environments          = []
      excluded_environments = []
      channels              = []
      tenant_tags           = []

      package {
        name                      = "sbom"
        package_id                = "com.octopus:octopub-frontend-sbom"
        acquisition_location      = "Server"
        extract_during_deployment = false
        feed_id                   = data.octopusdeploy_feeds.maven.feeds[0].id
        properties                = { Extract = "True" }
      }
      features = ["Octopus.Features.SubstituteInFiles"]
    }

    properties   = {}
    target_roles = []
  }
}