terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }
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
        "Octopus.Action.Terraform.Template"              = <<EOF
terraform {
  backend "pg" {
    conn_str = "postgres://terraform:terraform@terraformdb:5432/spaces?sslmode=disable"
  }
}

provider "octopusdeploy" {
  address  = "http://octopus:8080"
  api_key  = "API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  space_id = "Spaces-1"
}

output "space_id" {
  value = octopusdeploy_space.space.id
}

${file("../../../../spaces/octopus/terraform.tf")}
EOF
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
        "Octopus.Action.Terraform.AdditionalActionParams"       = ""
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

  step {
    condition           = "Success"
    name                = "Deploy Environments"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.TerraformApply"
      name                               = "Deploy Environments"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = false
      worker_pool_id                     = ""
      properties                         = {
        "Octopus.Action.Script.ScriptSource"             = "Inline"
        "Octopus.Action.Terraform.Template"              = <<EOF
terraform {
  backend "pg" {
    conn_str = "postgres://terraform:terraform@terraformdb:5432/environments?sslmode=disable"
  }
}

provider "octopusdeploy" {
  address  = "http://octopus:8080"
  api_key  = "API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  space_id = "Spaces-1"
}

${file("../../../../shared/environments/dev_test_prod/octopus/terraform.tf")}
EOF
        "Octopus.Action.Terraform.AllowPluginDownloads"  = "True"
        "Octopus.Action.Terraform.GoogleCloudAccount"    = "False"
        "Octopus.Action.GoogleCloud.UseVMServiceAccount" = "True"
        "Octopus.Action.Terraform.TemplateParameters"    = jsonencode({
          "space_id" = "#{Octopus.Action[Create Client Space].Output.TerraformValueOutputs[\"space_id\"]}"
        })
        "Octopus.Action.Terraform.Workspace"                    = "#{Octopus.Deployment.Tenant.Name}"
        "Octopus.Action.Terraform.PlanJsonOutput"               = "False"
        "Octopus.Action.Terraform.AzureAccount"                 = "False"
        "Octopus.Action.Terraform.ManagedAccount"               = "None"
        "Octopus.Action.GoogleCloud.ImpersonateServiceAccount"  = "False"
        "Octopus.Action.Terraform.AdditionalActionParams"       = ""
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

  step {
    condition           = "Success"
    name                = "Deploy Sync Environment"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.TerraformApply"
      name                               = "Deploy Sync Environment"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = false
      worker_pool_id                     = ""
      properties                         = {
        "Octopus.Action.Script.ScriptSource"             = "Inline"
        "Octopus.Action.Terraform.Template"              = <<EOF
terraform {
  backend "pg" {
    conn_str = "postgres://terraform:terraform@terraformdb:5432/sync_environment?sslmode=disable"
  }
}

provider "octopusdeploy" {
  address  = "http://octopus:8080"
  api_key  = "API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  space_id = "Spaces-1"
}

${file("../../../../shared/environments/sync/octopus/terraform.tf")}
EOF
        "Octopus.Action.Terraform.AllowPluginDownloads"  = "True"
        "Octopus.Action.Terraform.GoogleCloudAccount"    = "False"
        "Octopus.Action.GoogleCloud.UseVMServiceAccount" = "True"
        "Octopus.Action.Terraform.TemplateParameters"    = jsonencode({
          "space_id" = "#{Octopus.Action[Create Client Space].Output.TerraformValueOutputs[\"space_id\"]}"
        })
        "Octopus.Action.Terraform.Workspace"                    = "#{Octopus.Deployment.Tenant.Name}"
        "Octopus.Action.Terraform.PlanJsonOutput"               = "False"
        "Octopus.Action.Terraform.AzureAccount"                 = "False"
        "Octopus.Action.Terraform.ManagedAccount"               = "None"
        "Octopus.Action.GoogleCloud.ImpersonateServiceAccount"  = "False"
        "Octopus.Action.Terraform.AdditionalActionParams"       = ""
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

  step {
    condition           = "Success"
    name                = "Deploy Git Creds"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.TerraformApply"
      name                               = "Deploy Git Creds"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = false
      worker_pool_id                     = ""
      properties                         = {
        "Octopus.Action.Script.ScriptSource"             = "Inline"
        "Octopus.Action.Terraform.Template"              = <<EOF
terraform {
  backend "pg" {
    conn_str = "postgres://terraform:terraform@terraformdb:5432/gitcreds?sslmode=disable"
  }
}

provider "octopusdeploy" {
  address  = "http://octopus:8080"
  api_key  = "API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  space_id = "Spaces-1"
}

${file("../../../../shared/gitcreds/gitea/octopus/terraform.tf")}
EOF
        "Octopus.Action.Terraform.AllowPluginDownloads"  = "True"
        "Octopus.Action.Terraform.GoogleCloudAccount"    = "False"
        "Octopus.Action.GoogleCloud.UseVMServiceAccount" = "True"
        "Octopus.Action.Terraform.TemplateParameters"    = jsonencode({
          "space_id" = "#{Octopus.Action[Create Client Space].Output.TerraformValueOutputs[\"space_id\"]}"
        })
        "Octopus.Action.Terraform.Workspace"                    = "#{Octopus.Deployment.Tenant.Name}"
        "Octopus.Action.Terraform.PlanJsonOutput"               = "False"
        "Octopus.Action.Terraform.AzureAccount"                 = "False"
        "Octopus.Action.Terraform.ManagedAccount"               = "None"
        "Octopus.Action.GoogleCloud.ImpersonateServiceAccount"  = "False"
        "Octopus.Action.Terraform.AdditionalActionParams"       = ""
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

  step {
    condition           = "Success"
    name                = "Deploy Maven Feed"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.TerraformApply"
      name                               = "Deploy Maven Feed"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = false
      worker_pool_id                     = ""
      properties                         = {
        "Octopus.Action.Script.ScriptSource"             = "Inline"
        "Octopus.Action.Terraform.Template"              = <<EOF
terraform {
  backend "pg" {
    conn_str = "postgres://terraform:terraform@terraformdb:5432/mavenfeed?sslmode=disable"
  }
}

provider "octopusdeploy" {
  address  = "http://octopus:8080"
  api_key  = "API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  space_id = "Spaces-1"
}

${file("../../../../shared/feeds/maven/octopus/terraform.tf")}
EOF
        "Octopus.Action.Terraform.AllowPluginDownloads"  = "True"
        "Octopus.Action.Terraform.GoogleCloudAccount"    = "False"
        "Octopus.Action.GoogleCloud.UseVMServiceAccount" = "True"
        "Octopus.Action.Terraform.TemplateParameters"    = jsonencode({
          "space_id" = "#{Octopus.Action[Create Client Space].Output.TerraformValueOutputs[\"space_id\"]}"
        })
        "Octopus.Action.Terraform.Workspace"                    = "#{Octopus.Deployment.Tenant.Name}"
        "Octopus.Action.Terraform.PlanJsonOutput"               = "False"
        "Octopus.Action.Terraform.AzureAccount"                 = "False"
        "Octopus.Action.Terraform.ManagedAccount"               = "None"
        "Octopus.Action.GoogleCloud.ImpersonateServiceAccount"  = "False"
        "Octopus.Action.Terraform.AdditionalActionParams"       = ""
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

  step {
    condition           = "Success"
    name                = "Deploy DockerHub Feed"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.TerraformApply"
      name                               = "Deploy DockerHub Feed"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = false
      worker_pool_id                     = ""
      properties                         = {
        "Octopus.Action.Script.ScriptSource"             = "Inline"
        "Octopus.Action.Terraform.Template"              = <<EOF
terraform {
  backend "pg" {
    conn_str = "postgres://terraform:terraform@terraformdb:5432/dockerhubfeed?sslmode=disable"
  }
}

provider "octopusdeploy" {
  address  = "http://octopus:8080"
  api_key  = "API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  space_id = "Spaces-1"
}

${file("../../../../shared/feeds/dockerhub/octopus/terraform.tf")}
EOF
        "Octopus.Action.Terraform.AllowPluginDownloads"  = "True"
        "Octopus.Action.Terraform.GoogleCloudAccount"    = "False"
        "Octopus.Action.GoogleCloud.UseVMServiceAccount" = "True"
        "Octopus.Action.Terraform.TemplateParameters"    = jsonencode({
          "space_id" = "#{Octopus.Action[Create Client Space].Output.TerraformValueOutputs[\"space_id\"]}"
        })
        "Octopus.Action.Terraform.Workspace"                    = "#{Octopus.Deployment.Tenant.Name}"
        "Octopus.Action.Terraform.PlanJsonOutput"               = "False"
        "Octopus.Action.Terraform.AzureAccount"                 = "False"
        "Octopus.Action.Terraform.ManagedAccount"               = "None"
        "Octopus.Action.GoogleCloud.ImpersonateServiceAccount"  = "False"
        "Octopus.Action.Terraform.AdditionalActionParams"       = ""
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

  step {
    condition           = "Success"
    name                = "Deploy Hello World Project Group"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.TerraformApply"
      name                               = "Deploy Hello World Project Group"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = false
      worker_pool_id                     = ""
      properties                         = {
        "Octopus.Action.Script.ScriptSource"             = "Inline"
        "Octopus.Action.Terraform.Template"              = <<EOF
terraform {
  backend "pg" {
    conn_str = "postgres://terraform:terraform@terraformdb:5432/project_group_hello_world?sslmode=disable"
  }
}

provider "octopusdeploy" {
  address  = "http://octopus:8080"
  api_key  = "API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  space_id = "Spaces-1"
}

${file("../../../../shared/project_group/hello_world/octopus/terraform.tf")}
EOF
        "Octopus.Action.Terraform.AllowPluginDownloads"  = "True"
        "Octopus.Action.Terraform.GoogleCloudAccount"    = "False"
        "Octopus.Action.GoogleCloud.UseVMServiceAccount" = "True"
        "Octopus.Action.Terraform.TemplateParameters"    = jsonencode({
          "space_id" = "#{Octopus.Action[Create Client Space].Output.TerraformValueOutputs[\"space_id\"]}"
        })
        "Octopus.Action.Terraform.Workspace"                    = "#{Octopus.Deployment.Tenant.Name}"
        "Octopus.Action.Terraform.PlanJsonOutput"               = "False"
        "Octopus.Action.Terraform.AzureAccount"                 = "False"
        "Octopus.Action.Terraform.ManagedAccount"               = "None"
        "Octopus.Action.GoogleCloud.ImpersonateServiceAccount"  = "False"
        "Octopus.Action.Terraform.AdditionalActionParams"       = ""
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

  step {
    condition           = "Success"
    name                = "Deploy Azure Project Group"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.TerraformApply"
      name                               = "Deploy Azure Project Group"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = false
      worker_pool_id                     = ""
      properties                         = {
        "Octopus.Action.Script.ScriptSource"             = "Inline"
        "Octopus.Action.Terraform.Template"              = <<EOF
terraform {
  backend "pg" {
    conn_str = "postgres://terraform:terraform@terraformdb:5432/project_group_azure?sslmode=disable"
  }
}

provider "octopusdeploy" {
  address  = "http://octopus:8080"
  api_key  = "API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  space_id = "Spaces-1"
}

${file("../../../../shared/project_group/azure/octopus/terraform.tf")}
EOF
        "Octopus.Action.Terraform.AllowPluginDownloads"  = "True"
        "Octopus.Action.Terraform.GoogleCloudAccount"    = "False"
        "Octopus.Action.GoogleCloud.UseVMServiceAccount" = "True"
        "Octopus.Action.Terraform.TemplateParameters"    = jsonencode({
          "space_id" = "#{Octopus.Action[Create Client Space].Output.TerraformValueOutputs[\"space_id\"]}"
        })
        "Octopus.Action.Terraform.Workspace"                    = "#{Octopus.Deployment.Tenant.Name}"
        "Octopus.Action.Terraform.PlanJsonOutput"               = "False"
        "Octopus.Action.Terraform.AzureAccount"                 = "False"
        "Octopus.Action.Terraform.ManagedAccount"               = "None"
        "Octopus.Action.GoogleCloud.ImpersonateServiceAccount"  = "False"
        "Octopus.Action.Terraform.AdditionalActionParams"       = ""
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

  step {
    condition           = "Success"
    name                = "Deploy K8s Project Group"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.TerraformApply"
      name                               = "Deploy K8s Project Group"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = false
      worker_pool_id                     = ""
      properties                         = {
        "Octopus.Action.Script.ScriptSource"             = "Inline"
        "Octopus.Action.Terraform.Template"              = <<EOF
terraform {
  backend "pg" {
    conn_str = "postgres://terraform:terraform@terraformdb:5432/project_group_k8s?sslmode=disable"
  }
}

provider "octopusdeploy" {
  address  = "http://octopus:8080"
  api_key  = "API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  space_id = "Spaces-1"
}

${file("../../../../shared/project_group/k8s/octopus/terraform.tf")}
EOF
        "Octopus.Action.Terraform.AllowPluginDownloads"  = "True"
        "Octopus.Action.Terraform.GoogleCloudAccount"    = "False"
        "Octopus.Action.GoogleCloud.UseVMServiceAccount" = "True"
        "Octopus.Action.Terraform.TemplateParameters"    = jsonencode({
          "space_id" = "#{Octopus.Action[Create Client Space].Output.TerraformValueOutputs[\"space_id\"]}"
        })
        "Octopus.Action.Terraform.Workspace"                    = "#{Octopus.Deployment.Tenant.Name}"
        "Octopus.Action.Terraform.PlanJsonOutput"               = "False"
        "Octopus.Action.Terraform.AzureAccount"                 = "False"
        "Octopus.Action.Terraform.ManagedAccount"               = "None"
        "Octopus.Action.GoogleCloud.ImpersonateServiceAccount"  = "False"
        "Octopus.Action.Terraform.AdditionalActionParams"       = ""
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

