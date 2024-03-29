variable "project_name" {
  type    = string
}

variable "project_description" {
  type    = string
}

variable "argocd_application_development" {
  type    = string
}

variable "argocd_application_test" {
  type    = string
}

variable "argocd_application_production" {
  type    = string
}

variable "argocd_version_image" {
  type    = string
}

variable "argocd_sbom_version_image" {
  type    = string
}

variable "argocd_sbom_package_id" {
  type    = string
}

resource "octopusdeploy_variable" "argocd_overview_dashboard_dev_env_metadata" {
  owner_id    = octopusdeploy_project.project_overview_dashboard.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[${var.argocd_application_development}].Environment"
  value       = "Development"
  description = "This variable links this project's Development environment to the ${var.argocd_application_development} ArgoCD application in the argocd namespace"
}

resource "octopusdeploy_variable" "argocd_overview_dashboard_dev_version_metadata" {
  owner_id    = octopusdeploy_project.project_overview_dashboard.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[${var.argocd_application_development}].ImageForReleaseVersion"
  value       = var.argocd_version_image
  description = "This variable indicates that the ${var.argocd_application_development} images deployed by the ArgoCD application is used to build the Octopus release numbers"
}

resource "octopusdeploy_variable" "argocd_overview_dashboard_test_env_metadata" {
  owner_id    = octopusdeploy_project.project_overview_dashboard.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[${var.argocd_application_test}].Environment"
  value       = "Test"
  description = "This variable links this project's Test environment to the ${var.argocd_application_test} ArgoCD application in the argocd namespace"
}

resource "octopusdeploy_variable" "argocd_overview_dashboard_test_version_metadata" {
  owner_id    = octopusdeploy_project.project_overview_dashboard.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[${var.argocd_application_test}].ImageForReleaseVersion"
  value       = var.argocd_version_image
  description = "This variable indicates that the ${var.argocd_application_test} images deployed by the ArgoCD application is used to build the Octopus release numbers"
}

resource "octopusdeploy_variable" "argocd_overview_dashboard_prod_env_metadata" {
  owner_id    = octopusdeploy_project.project_overview_dashboard.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[${var.argocd_application_production}].Environment"
  value       = "Production"
  description = "This variable links this project's Production environment to the ${var.argocd_application_production} ArgoCD application in the argocd namespace"
}

resource "octopusdeploy_variable" "argocd_overview_dashboard_prod_version_metadata" {
  owner_id    = octopusdeploy_project.project_overview_dashboard.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[${var.argocd_application_production}].ImageForReleaseVersion"
  value       = var.argocd_version_image
  description = "This variable indicates that the ${var.argocd_application_production} images deployed by the ArgoCD application is used to build the Octopus release numbers"
}

resource "octopusdeploy_variable" "argocd_overview_dashboard_prod_package_version_metadata" {
  owner_id    = octopusdeploy_project.project_overview_dashboard.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[${var.argocd_application_production}].ImageForPackageVersion[Check for Vulnerabilities:sbom]"
  value       = var.argocd_version_image
  description = "This variable indicates that the ${var.argocd_application_production} images deployed by the ArgoCD application is used to build the Octopus release numbers"
}

resource "octopusdeploy_variable" "argocd_overview_dashboard_test_package_version_metadata" {
  owner_id    = octopusdeploy_project.project_overview_dashboard.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[${var.argocd_application_test}].ImageForPackageVersion[Check for Vulnerabilities:sbom]"
  value       = var.argocd_version_image
  description = "This variable indicates that the ${var.argocd_application_test} images deployed by the ArgoCD application is used to build the Octopus release numbers"
}

resource "octopusdeploy_variable" "argocd_overview_dashboard_dev_package_version_metadata" {
  owner_id    = octopusdeploy_project.project_overview_dashboard.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[${var.argocd_application_development}].ImageForPackageVersion[Check for Vulnerabilities:sbom]"
  value       = var.argocd_version_image
  description = "This variable indicates that the ${var.argocd_application_development} images deployed by the ArgoCD application is used to build the Octopus release numbers"
}

resource "octopusdeploy_project" "project_overview_dashboard" {
  name                                 = var.project_name
  description                          = var.project_description
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
    condition           = "Success"
    name                = "Check for Vulnerabilities"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

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
        "Octopus.Action.Script.ScriptBody"         = file("${path.module}/../scripts/vulnerability_scan.sh")
        "Octopus.Action.Script.ScriptSource"       = "Inline"
        "Octopus.Action.Script.Syntax"             = "Bash"
      }
      environments          = []
      excluded_environments = []
      channels              = []
      tenant_tags           = []

      package {
        name                      = "sbom"
        package_id                = var.argocd_sbom_package_id
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