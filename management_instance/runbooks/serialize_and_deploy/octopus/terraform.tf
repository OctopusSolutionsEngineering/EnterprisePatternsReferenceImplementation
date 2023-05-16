terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }
  }
}

locals {
  backend               = "#{Octopus.Project.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"_\"}"
  workspace             = "#{Octopus.Deployment.Tenant.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"_\"}_${var.project_name_override ? "#{Exported.Project.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"_\"}" : "#{Octopus.Project.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"_\"}"}"
  project_name_variable = "project_#{Octopus.Project.Name | ToLower | Replace \"[^a-zA-Z0-9]\" \"_\"}_name"
}

variable "project_name" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The name of the project to attach the runbooks to."
}

variable "project_name_override" {
  type        = bool
  nullable    = false
  sensitive   = false
  default     = true
  description = "Whether the downstream project name can be customized. If false, the downstream project has the same name as the upstream project."
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

variable "runbook_backend_service_deploy_project_name" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The name of the project exported from Deploy Project"
  default     = "__ 2. Deploy Project"
}

variable "compose_project" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The name of the project containing the runbook required to compose in global resource"
  default     = ""
}

variable "compose_runbook" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The name of the runbook required to compose in global resource"
  default     = ""
}

variable "create_space_project" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The name of the project containing the runbook required to create the space"
  default     = ""
}

variable "create_space_runbook" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The name of the runbook required to create the space"
  default     = ""
}

resource "octopusdeploy_runbook" "runbook_backend_service_deploy_project" {
  name                        = var.runbook_backend_service_deploy_project_name
  project_id                  = data.octopusdeploy_projects.project.projects[0].id
  environment_scope           = "Specified"
  environments                = [data.octopusdeploy_environments.sync.environments[0].id]
  force_package_download      = false
  default_guided_failure_mode = "EnvironmentDefault"
  description                 = "This project deploys the package created by the Serialize Project runbook to a space."
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
      worker_pool_id                     = "${data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id}"
      properties                         = {
        "Octopus.Action.Script.Syntax"       = "Python"
        "Octopus.Action.Script.ScriptBody"   = templatefile("../../shared_scripts/serialize_project.py", {})
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
  name                        = "${var.runbook_backend_service_serialize_project_name}"
  project_id                  = "${data.octopusdeploy_projects.project.projects[0].id}"
  environment_scope           = "Specified"
  environments                = [data.octopusdeploy_environments.sync.environments[0].id]
  force_package_download      = false
  default_guided_failure_mode = "EnvironmentDefault"
  description                 = "This runbook serializes a project to HCL, packages it up, and pushes the package to Octopus."
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
echo "Pulling postgres image"
echo "##octopus[stdout-verbose]"
docker pull postgres
echo "##octopus[stdout-default]"
DATABASE=$(dig +short terraformdb)
docker run -e "PGPASSWORD=terraform" --entrypoint '/usr/bin/flock' postgres /root/createdb.lock /bin/bash -c "echo \"SELECT 'CREATE DATABASE ${local.backend}' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${local.backend}')\gexec\" | /usr/bin/psql -h $${DATABASE} -v ON_ERROR_STOP=1 --username 'terraform'"
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
    name                = "Trigger Create Space"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "Trigger Create Space"
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
if [[ -z "${var.create_space_project}" ]]
then
  echo "No compose project to run"
  exit 0
fi

octo \
  run-runbook \
  --server 'http://octopus:8080' \
  --apiKey 'API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' \
  --space 'Default' \
  --project '${var.create_space_project}' \
  --runbook '${var.create_space_runbook}' \
  --environment 'Sync' \
  --tenant '#{Octopus.Deployment.Tenant.Name}' \
  --waitForRun
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
    name                = "Compose Specialized Resource"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "Compose Specialized Resource"
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
if [[ -z "${var.compose_project}" ]]
then
  echo "No compose project to run"
  exit 0
fi

octo \
  run-runbook \
  --server 'http://octopus:8080' \
  --apiKey 'API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' \
  --space 'Default' \
  --project '${var.compose_project}' \
  --runbook '${var.compose_runbook}' \
  --environment 'Sync' \
  --tenant '#{Octopus.Deployment.Tenant.Name}' \
  --waitForRun
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
    name                = "Lookup New Space"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "Lookup New Space"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = true
      is_required                        = false
      worker_pool_id                     = data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id
      properties                         = {
        "Octopus.Action.Script.Syntax"     = "Python"
        "Octopus.Action.Script.ScriptBody" = file("../../shared_scripts/space_lookup.py")
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
        "Octopus.Action.Terraform.AdditionalActionParams"       = "-var=\"octopus_server=#{ManagedTenant.Octopus.Url}\" -var=\"octopus_space_id=#{Octopus.Action[Lookup New Space].Output.SpaceID}\" -var=\"octopus_apikey=#{ManagedTenant.Octopus.ApiKey}\" ${var.project_name_override ? "-var=\"${local.project_name_variable}=#{Exported.Project.Name}\"" : ""}"
        "Octopus.Action.Aws.AssumeRole"                         = "False"
        "Octopus.Action.Aws.Region"                             = ""
        "Octopus.Action.Terraform.AllowPluginDownloads"         = "True"
        "Octopus.Action.Terraform.AzureAccount"                 = "False"
        "Octopus.Action.AwsAccount.Variable"                    = ""
        "Octopus.Action.GoogleCloud.UseVMServiceAccount"        = "True"
        "Octopus.Action.Script.ScriptSource"                    = "Package"
        "Octopus.Action.Terraform.RunAutomaticFileSubstitution" = "False"
        "Octopus.Action.Terraform.AdditionalInitParams"         = "-backend-config=\"conn_str=postgres://terraform:terraform@terraformdb:5432/${local.backend}?sslmode=disable\""
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
        package_id           = "Hello_World"
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
