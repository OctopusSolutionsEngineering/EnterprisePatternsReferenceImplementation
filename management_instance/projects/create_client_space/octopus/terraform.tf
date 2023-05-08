terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.0" }
  }
}

data "octopusdeploy_library_variable_sets" "library_variable_set_octopus_server" {
  ids          = null
  partial_name = "Octopus Server"
  skip         = 0
  take         = 1
}

data "octopusdeploy_environments" "environment_sync" {
  ids          = null
  partial_name = "Sync"
  skip         = 0
  take         = 1
}

variable "runbook____create_client_space_create_client_space_name" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The name of the project exported from Create Client Space"
  default     = "Create Client Space"
}

resource "octopusdeploy_runbook" "runbook____create_client_space_create_client_space" {
  name                        = "${var.runbook____create_client_space_create_client_space_name}"
  project_id                  = "${octopusdeploy_project.project____create_client_space.id}"
  environment_scope           = "Specified"
  environments                = ["${data.octopusdeploy_environments.environment_sync.environments[0].id}"]
  force_package_download      = false
  default_guided_failure_mode = "EnvironmentDefault"
  description                 = ""
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

resource "octopusdeploy_deployment_process" "deployment_process_project____create_client_space" {
  project_id = "${octopusdeploy_project.project____create_client_space.id}"
}

data "octopusdeploy_lifecycles" "lifecycle_simple" {
  ids          = null
  partial_name = "Simple"
  skip         = 0
  take         = 1
}

variable "project____create_client_space_name" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The name of the project exported from __ Create Client Space"
  default     = "__ Create Client Space"
}

resource "octopusdeploy_project" "project____create_client_space" {
  name                                 = "${var.project____create_client_space_name}"
  auto_create_release                  = false
  default_guided_failure_mode          = "EnvironmentDefault"
  default_to_skip_if_already_installed = false
  description                          = ""
  discrete_channel_release             = false
  is_disabled                          = false
  is_version_controlled                = false
  lifecycle_id                         = "${data.octopusdeploy_lifecycles.lifecycle_simple.lifecycles[0].id}"
  project_group_id                     = "${data.octopusdeploy_project_groups.project_group_client_space.project_groups[0].id}"
  included_library_variable_sets       = [
    "${data.octopusdeploy_library_variable_sets.library_variable_set_octopus_server.library_variable_sets[0].id}"
  ]
  tenanted_deployment_participation    = "Untenanted"

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }

  versioning_strategy {
    template = "#{Octopus.Version.LastMajor}.#{Octopus.Version.LastMinor}.#{Octopus.Version.NextPatch}"
  }
}

resource "octopusdeploy_runbook_process" "runbook_process____create_client_space_create_client_space" {
  runbook_id = "${octopusdeploy_runbook.runbook____create_client_space_create_client_space.id}"

  step {
    condition           = "Success"
    name                = "Create Client Space"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.TerraformApply"
      name                               = "Create Client Space"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = false
      worker_pool_id                     = ""
      properties                         = {
        "Octopus.Action.Script.ScriptSource"             = "Inline"
        "Octopus.Action.Terraform.Template"              = "terraform {\n  backend \"pg\" {\n    conn_str = \"postgres://terraform:terraform@terraformdb:5432/spaces?sslmode=disable\"\n  }\n}\n\nterraform {\n  required_providers {\n    octopusdeploy = { source = \"OctopusDeployLabs/octopusdeploy\", version = \"0.12.0\" }\n  }\n}\n\nprovider \"octopusdeploy\" {\n  address  = \"http://octopus:8080\"\n  api_key  = \"API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\"\n  space_id = \"Spaces-1\"\n}\n\nvariable \"space_name\" {\n  type        = string\n  nullable    = false\n  sensitive   = false\n  description = \"The name of the new space\"\n}\n\nresource \"octopusdeploy_space\" \"space\" {\n  description                 = \"A space for team $${var.space_name}.\"\n  name                        = var.space_name\n  is_default                  = false\n  is_task_queue_stopped       = false\n  space_managers_team_members = []\n  space_managers_teams        = [\"teams-everyone\"]\n}"
        "Octopus.Action.Terraform.AllowPluginDownloads"  = "True"
        "Octopus.Action.Terraform.GoogleCloudAccount"    = "False"
        "Octopus.Action.GoogleCloud.UseVMServiceAccount" = "True"
        "Octopus.Action.Terraform.TemplateParameters"    = jsonencode({
          "space_name" = "#{Octopus.Deployment.Tenant.Name}"
        })
        "Octopus.Action.Terraform.Workspace"                    = "#{Octopus.Deployment.Tenant.Name}"
        "Octopus.Action.Terraform.PlanJsonOutput"               = "False"
        "Octopus.Action.Terraform.AzureAccount"                 = "False"
        "Octopus.Action.Terraform.ManagedAccount"               = "None"
        "Octopus.Action.GoogleCloud.ImpersonateServiceAccount"  = "False"
        "Octopus.Action.Terraform.AdditionalActionParams"       = "-var=space_name=#{Octopus.Deployment.Tenant.Name}"
        "Octopus.Action.Terraform.RunAutomaticFileSubstitution" = "True"
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

data "octopusdeploy_channels" "channel__default" {
  ids          = null
  partial_name = "Default"
  skip         = 0
  take         = 1
}

variable "project_group_client_space_name" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The name of the project group to lookup"
  default     = "Client Space"
}
data "octopusdeploy_project_groups" "project_group_client_space" {
  ids          = null
  partial_name = "${var.project_group_client_space_name}"
  skip         = 0
  take         = 1
}

