terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.0" }
  }
}

locals {
  workspace             = "#{Octopus.Deployment.Tenant.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"_\"}_#{Exported.Project.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"_\"}"
  new_repo              = "#{Octopus.Deployment.Tenant.Name | ToLower}_#{Exported.Project.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"_\"}"
  project_name_variable = "project_#{Octopus.Project.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"_\"}_name"
  cac_org               = "octopuscac"
  cac_password          = "Password01!"
  cac_username          = "octopus"
  cac_host              = "gitea:3000"
  cac_proto             = "http"
  package               = "#{Octopus.Project.Name | Replace \"[^a-zA-Z0-9]\" \"_\"}"
  git_url_var_name      = "project_#{Octopus.Project.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"_\"}_git_url"
  template_repo         = "#{Octopus.Project.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"_\"}"
}

variable "project_name" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The name of the project to attach the runbooks to."
}

data "octopusdeploy_worker_pools" "workerpool_default" {
  name = "Default Worker Pool"
  ids  = null
  skip = 0
  take = 1
}

data "octopusdeploy_feeds" "feed_octopus_server__built_in_" {
  feed_type    = "BuiltIn"
  ids          = null
  partial_name = ""
  skip         = 0
  take         = 1
}

data "octopusdeploy_feeds" "feed_docker" {
  feed_type    = "Docker"
  ids          = null
  partial_name = "Docker"
  skip         = 0
  take         = 1
}

data "octopusdeploy_projects" "project" {
  cloned_from_project_id = null
  ids                    = []
  is_clone               = false
  name                   = var.project_name
  partial_name           = null
  skip                   = 0
  take                   = 1
}

data "octopusdeploy_environments" "sync" {
  ids          = []
  partial_name = "Sync"
  skip         = 0
  take         = 1
}

resource "octopusdeploy_variable" "octopus_api_key" {
  name         = "Exported.Project.Name"
  type         = "String"
  description  = "The name of the new project"
  is_sensitive = false
  is_editable  = true
  owner_id     = data.octopusdeploy_projects.project.projects[0].id
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
  owner_id     = data.octopusdeploy_projects.project.projects[0].id
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
  owner_id     = data.octopusdeploy_projects.project.projects[0].id
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

variable "runbook_backend_service_deploy_project_name" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The name of the project exported from Deploy Project"
  default     = "__ 2. Fork and Deploy Project"
}

resource "octopusdeploy_runbook" "runbook_backend_service_deploy_project" {
  name                        = var.runbook_backend_service_deploy_project_name
  project_id                  = data.octopusdeploy_projects.project.projects[0].id
  environment_scope           = "Specified"
  environments                = [data.octopusdeploy_environments.sync.environments[0].id]
  force_package_download      = false
  default_guided_failure_mode = "EnvironmentDefault"
  description                 = "This project forks the repo holding this project and deploys the package created by the Serialize Project runbook to a new space setting the CaC URL to the forked repo."
  multi_tenancy_mode          = "Tenanted"

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

resource "octopusdeploy_runbook_process" "runbook_process_backend_service_serialize_project" {
  runbook_id = "${octopusdeploy_runbook.runbook_backend_service_serialize_project.id}"

  step {
    condition           = "Success"
    name                = "Serialize Project"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "Serialize Project"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = true
      is_required                        = false
      worker_pool_id                     = data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id
      properties                         = {
        "Octopus.Action.Script.Syntax"       = "Bash"
        "Octopus.Action.Script.ScriptBody" = templatefile("../../shared_scripts/serialize_project.sh", {})
        "Octopus.Action.Script.ScriptSource" = "Inline"
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
}

variable "runbook_backend_service_serialize_project_name" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The name of the project exported from Serialize Project"
  default     = "__ 1. Serialize Project"
}

resource "octopusdeploy_runbook" "runbook_backend_service_serialize_project" {
  name                        = var.runbook_backend_service_serialize_project_name
  project_id                  = data.octopusdeploy_projects.project.projects[0].id
  environment_scope           = "Specified"
  environments                = [data.octopusdeploy_environments.sync.environments[0].id]
  force_package_download      = false
  default_guided_failure_mode = "EnvironmentDefault"
  description                 = "This serializes a project to HCL (excluding the deployment process if it is a CaC project), packages it up, and pushes the package to Octopus."
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

resource "octopusdeploy_runbook_process" "runbook_process_backend_service_deploy_project" {
  runbook_id = octopusdeploy_runbook.runbook_backend_service_deploy_project.id

  step {
    condition           = "Success"
    name                = "Create the State Table"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "Create the State Table"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = false
      worker_pool_id                     = data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id
      properties                         = {
        "Octopus.Action.Script.ScriptSource" = "Inline"
        "Octopus.Action.Script.Syntax"       = "Bash"
        "Octopus.Action.Script.ScriptBody"   = <<EOT
echo "##octopus[stdout-verbose]"
docker pull postgres
echo "##octopus[stdout-default]"
DATABASE=$(dig +short terraformdb)
docker run -e "PGPASSWORD=terraform" --entrypoint '/usr/bin/psql' postgres -h $${DATABASE} -v ON_ERROR_STOP=1 --username "terraform" -c "CREATE DATABASE project_sync" 2>&1
exit 0
EOT
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
    name                = "Fork Git Repo"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "Fork Git Repo"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = true
      is_required                        = false
      worker_pool_id                     = data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id
      properties                         = {
        "Octopus.Action.Script.Syntax"     = "Bash"
        "Octopus.Action.Script.ScriptBody" = templatefile("../../shared_scripts/fork_repo.sh", {
          cac_host      = local.cac_host,
          cac_proto     = local.cac_proto,
          cac_username  = local.cac_username,
          cac_org       = local.cac_org,
          cac_password  = local.cac_password,
          new_repo      = local.new_repo,
          template_repo = local.template_repo
        })
        "Octopus.Action.Script.ScriptSource" = "Inline"
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
        "Octopus.Action.Terraform.GoogleCloudAccount"           = "False"
        "Octopus.Action.Terraform.TemplateDirectory"            = "space_population"
        "Octopus.Action.Terraform.AdditionalActionParams"       = "-var=\"octopus_server=#{ManagedTenant.Octopus.Server}\" -var=\"octopus_space_id=#{ManagedTenant.Octopus.SpaceId}\" -var=\"octopus_apikey=#{ManagedTenant.Octopus.ApiKey}\" -var=\"${local.git_url_var_name}=${local.cac_proto}://${local.cac_host}/${local.cac_org}/${local.new_repo}.git\" -var=\"${local.project_name_variable}=#{Exported.Project.Name}\""
        "Octopus.Action.Aws.AssumeRole"                         = "False"
        "Octopus.Action.Aws.Region"                             = ""
        "Octopus.Action.Terraform.AllowPluginDownloads"         = "True"
        "Octopus.Action.Terraform.AzureAccount"                 = "False"
        "Octopus.Action.AwsAccount.Variable"                    = ""
        "Octopus.Action.GoogleCloud.UseVMServiceAccount"        = "True"
        "Octopus.Action.Script.ScriptSource"                    = "Package"
        "Octopus.Action.Terraform.RunAutomaticFileSubstitution" = "False"
        "Octopus.Action.Terraform.AdditionalInitParams"         = "-backend-config=\"conn_str=postgres://terraform:terraform@terraformdb:5432/project_sync?sslmode=disable\""
        "Octopus.Action.GoogleCloud.ImpersonateServiceAccount"  = "False"
        "Octopus.Action.Terraform.PlanJsonOutput"               = "False"
        "Octopus.Action.Terraform.ManagedAccount"               = ""
        "OctopusUseBundledTooling"                              = "False"
        "Octopus.Action.AwsAccount.UseInstanceRole"             = "False"
        "Octopus.Action.Terraform.FileSubstitution"             = "**/project_variable_sensitive*.tf"
        "Octopus.Action.Package.DownloadOnTentacle"             = "False"
        "Octopus.Action.Terraform.Workspace"                    = local.workspace
      }

      environments          = []
      excluded_environments = []
      channels              = []
      tenant_tags           = []

      primary_package {
        package_id           = local.package
        acquisition_location = "Server"
        feed_id              = data.octopusdeploy_feeds.feed_octopus_server__built_in_.feeds[0].id
        properties           = { SelectionMode = "immediate" }
      }

      features = []
    }

    properties   = {}
    target_roles = []
  }
}
