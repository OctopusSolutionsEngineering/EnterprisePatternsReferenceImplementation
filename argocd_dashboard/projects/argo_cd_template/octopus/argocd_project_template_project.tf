resource "octopusdeploy_variable" "argocd_template_git_url" {
  owner_id    = octopusdeploy_project.argocd_project_template.id
  type        = "String"
  name        = "Template.Git.Repo.Url"
  value       = "http://gitea:3000/octopuscac/argo_cd.git"
  description = "The git URL repo"
}

resource "octopusdeploy_variable" "argocd_template_git_username" {
  owner_id    = octopusdeploy_project.argocd_project_template.id
  type        = "String"
  name        = "Template.Git.User.Name"
  value       = "octopus"
  description = "The git username"
}

resource "octopusdeploy_variable" "argocd_template_git_password" {
  owner_id        = octopusdeploy_project.argocd_project_template.id
  type            = "Sensitive"
  name            = "Template.Git.User.Password"
  is_sensitive    = true
  sensitive_value = "Password01!"
  description     = "The git password"
}

resource "octopusdeploy_variable" "argocd_template_git_destinationpath" {
  owner_id    = octopusdeploy_project.argocd_project_template.id
  type        = "String"
  name        = "Template.Git.Destination.Path"
  value       = "/argocd/#{ArgoCD.Project.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"-\"}"
  description = "The directory that represents the destination for the template project"
}

resource "octopusdeploy_variable" "project_name" {
  name         = "ArgoCD.Project.Name"
  type         = "String"
  description  = "The name of the new project."
  is_sensitive = false
  is_editable  = true
  owner_id     = octopusdeploy_project.argocd_project_template.id
  value        = ""

  prompt {
    description = "The name of the new project."
    label       = "Project Name"
    is_required = true
  }
}

resource "octopusdeploy_project" "argocd_project_template" {
  name                                 = "Template ArgoCD Projects"
  description                          = "This project is used to create new ArgoCD projects from a template."
  auto_create_release                  = false
  default_guided_failure_mode          = "EnvironmentDefault"
  default_to_skip_if_already_installed = false
  discrete_channel_release             = false
  is_disabled                          = false
  is_version_controlled                = false
  lifecycle_id                         = data.octopusdeploy_lifecycles.lifecycle_simple.lifecycles[0].id
  project_group_id                     = data.octopusdeploy_project_groups.project_group_platform_engineering.project_groups[0].id
  included_library_variable_sets       = [data.octopusdeploy_library_variable_sets.argo_cd.library_variable_sets[0].id]
  tenanted_deployment_participation    = "Untenanted"

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }
}

resource "octopusdeploy_runbook" "runbook_create_project" {
  name                        = "Create ArgoCD Project"
  project_id                  = octopusdeploy_project.argocd_project_template.id
  environment_scope           = "Specified"
  environments                = [data.octopusdeploy_environments.admin.environments[0].id]
  force_package_download      = false
  default_guided_failure_mode = "EnvironmentDefault"
  description                 = "This runbook creates a new ArgoCD project."
  multi_tenancy_mode          = "Untenanted"

  retention_policy {
    quantity_to_keep    = 100
    should_keep_forever = false
  }

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }
}

resource "octopusdeploy_runbook_process" "runbook_process_create_project" {
  runbook_id = octopusdeploy_runbook.runbook_create_project.id

  step {
    condition           = "Success"
    name                = "Create Git Files"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "Create Git Files"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = false
      worker_pool_id                     = data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id
      properties                         = {
        "Octopus.Action.SubstituteInFiles.TargetFiles" = "**/*.yaml"
        "Octopus.Action.RunOnServer"                   = "true"
        "Octopus.Action.Script.ScriptSource"           = "Inline"
        "Octopus.Action.Script.Syntax"                 = "PowerShell"
        "Octopus.Action.Script.ScriptBody"             = file("${path.module}/../../scripts/Clone-CopyFromPackage-Push.ps1")
      }
      environments          = [data.octopusdeploy_environments.admin.environments[0].id]
      excluded_environments = []
      channels              = []
      tenant_tags           = []
      features              = ["Octopus.Features.SubstituteInFiles"]

      # This package has been created to represent the deferred package that a step template selects
      package {
        name                      = "Template.Package.Reference"
        package_id                = "argocd_template"
        acquisition_location      = "Server"
        extract_during_deployment = false
        feed_id                   = data.octopusdeploy_feeds.feed_octopus_server__built_in_.feeds[0].id
        properties                = {
          Extract       = "True",
          Purpose       = "",
          SelectionMode = "immediate",
        }
      }
    }

    properties   = {}
    target_roles = []
  }

  step {
    condition           = "Success"
    name                = "Deploy the Project"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.TerraformApply"
      name                               = "Deploy the Project"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = true
      is_required                        = false
      worker_pool_id                     = data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id
      properties                         = {
        "Octopus.Action.AutoRetry.MaximumCount"                 = "3"
        "Octopus.Action.Terraform.GoogleCloudAccount"           = "False"
        "Octopus.Action.Terraform.TemplateDirectory"            = "argo_cd_dashboard/pgbackend"
        "Octopus.Action.Terraform.AdditionalActionParams"       = "-var=\"octopus_server=http://octopus:8080\" -var=\"octopus_space_id=#{Octopus.Space.Id}\" -var=\"project_name=Overview: #{ArgoCD.Project.Name}\" -var=\"project_description=Dashboard showing the status of ArgoCD deployments\" -var=\"argocd_version_image=\" -var=\"argocd_sbom_version_image=\" -var=\"argocd_application_development=argocd/#{ArgoCD.Project.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"-\"}-development\" -var=\"argocd_application_test=argocd/#{ArgoCD.Project.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"-\"}-test\" -var=\"argocd_application_production=argocd/#{ArgoCD.Project.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"-\"}-production\""
        "Octopus.Action.Aws.AssumeRole"                         = "False"
        "Octopus.Action.Aws.Region"                             = ""
        "Octopus.Action.Terraform.AllowPluginDownloads"         = "True"
        "Octopus.Action.Terraform.AzureAccount"                 = "False"
        "Octopus.Action.AwsAccount.Variable"                    = ""
        "Octopus.Action.GoogleCloud.UseVMServiceAccount"        = "True"
        "Octopus.Action.Script.ScriptSource"                    = "Package"
        "Octopus.Action.Terraform.RunAutomaticFileSubstitution" = "False"
        "Octopus.Action.Terraform.AdditionalInitParams"         = "-backend-config=\"conn_str=postgres://terraform:terraform@terraformdb:5432/project_argo_cd_dashboard?sslmode=disable\""
        "Octopus.Action.GoogleCloud.ImpersonateServiceAccount"  = "False"
        "Octopus.Action.Terraform.PlanJsonOutput"               = "False"
        "Octopus.Action.Terraform.ManagedAccount"               = ""
        "OctopusUseBundledTooling"                              = "False"
        "Octopus.Action.AwsAccount.UseInstanceRole"             = "False"
        "Octopus.Action.Terraform.FileSubstitution"             = ""
        "Octopus.Action.Package.DownloadOnTentacle"             = "False"
        "Octopus.Action.Terraform.Workspace"                    = "#{ArgoCD.Project.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"-\"}"
      }

      environments          = []
      excluded_environments = []
      channels              = []
      tenant_tags           = []

      primary_package {
        package_id           = "argocd_octopus_projects"
        acquisition_location = "Server"
        feed_id              = data.octopusdeploy_feeds.feed_octopus_server__built_in_.feeds[0].id
        properties           = { SelectionMode = "immediate" }
      }

      features = []
    }

    properties   = {}
    target_roles = []
  }

  step {
    condition            = "Success"
    name                 = "Create ArgoCD Application"
    package_requirement  = "LetOctopusDecide"
    start_trigger        = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.KubernetesDeployRawYaml"
      name                               = "Create ArgoCD Application"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = false
      worker_pool_id                     = ""
      worker_pool_variable               = ""
      properties                         = {
        "Octopus.Action.Script.ScriptSource" = "Package"
        "Octopus.Action.KubernetesContainers.CustomResourceYamlFileName" = "parent_application.yaml"
        "Octopus.Action.Package.DownloadOnTentacle" = "False"
        "Octopus.Action.Kubernetes.ResourceStatusCheck" = "False"
        "Octopus.Action.Kubernetes.DeploymentTimeout" = "180"
      }
      environments          = []
      excluded_environments = []
      channels              = []
      tenant_tags           = []
      features              = []

      primary_package {
        package_id           = "argocd_template"
        acquisition_location = "Server"
        feed_id              = data.octopusdeploy_feeds.feed_octopus_server__built_in_.feeds[0].id
        properties           = { SelectionMode = "immediate" }
      }
    }

    properties   = {}
    target_roles = ["k8s"]
  }
}