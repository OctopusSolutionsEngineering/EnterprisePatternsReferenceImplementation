terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }
  }
}

variable "existing_project_group" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The name of the existing project group to place the project into."
  default     = "Azure"
}

variable "project_name" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The name of the new project."
  default     = "Azure Web App CaC"
}

data "octopusdeploy_lifecycles" "lifecycle" {
  ids          = null
  partial_name = "DevSecOps"
  skip         = 0
  take         = 1
}

data "octopusdeploy_accounts" "azure" {
  partial_name = "Azure"
  skip         = 0
  take         = 1
}

data "octopusdeploy_feeds" "docker" {
  feed_type    = "Docker"
  partial_name = "Docker"
  skip         = 0
  take         = 1
}

data "octopusdeploy_feeds" "maven" {
  feed_type    = "Maven"
  partial_name = "Sales Maven Feed"
  skip         = 0
  take         = 1
}

data "octopusdeploy_environments" "security" {
  partial_name = "Security"
  skip         = 0
  take         = 1
}

data "octopusdeploy_library_variable_sets" "octopus_server" {
  partial_name = "Octopus Server"
  skip         = 0
  take         = 1
}

data "octopusdeploy_library_variable_sets" "azure" {
  partial_name = "Azure"
  skip         = 0
  take         = 1
}


data "octopusdeploy_library_variable_sets" "variable" {
  partial_name = "This Instance"
  skip         = 0
  take         = 1
}

data "octopusdeploy_worker_pools" "workerpool_default" {
  name = "Default Worker Pool"
  ids  = null
  skip = 0
  take = 1
}

data "octopusdeploy_project_groups" "project_group" {
  partial_name = var.existing_project_group
  skip         = 0
  take         = 1
}

data "octopusdeploy_git_credentials" "gitcredential" {
  name = "Git"
  skip = 0
  take = 1
}

resource "octopusdeploy_variable" "package" {
  owner_id = octopusdeploy_project.project.id
  type     = "String"
  name     = "Azure.WebApp.PackageId"
  value    = "octopussamples/octopub"
}

resource "octopusdeploy_project_group" "project_group" {
  count = var.existing_project_group == "" ? 1 : 0
  name  = "Azure"
}

resource "octopusdeploy_project" "project" {
  lifecycle {
    ignore_changes = [
      connectivity_policy,
    ]
  }

  name                                 = var.project_name
  description                          = "A template project used to populate a Git repo to be forked by individual tenants."
  auto_create_release                  = false
  default_guided_failure_mode          = "EnvironmentDefault"
  default_to_skip_if_already_installed = false
  discrete_channel_release             = false
  is_disabled                          = false
  is_version_controlled                = true
  lifecycle_id                         = "${data.octopusdeploy_lifecycles.lifecycle.lifecycles[0].id}"
  project_group_id                     = var.existing_project_group == "" ? octopusdeploy_project_group.project_group[0].id : data.octopusdeploy_project_groups.project_group.project_groups[0].id
  included_library_variable_sets       = [
    data.octopusdeploy_library_variable_sets.variable.library_variable_sets[0].id,
    data.octopusdeploy_library_variable_sets.azure.library_variable_sets[0].id,
    data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].id
  ]
  tenanted_deployment_participation    = "Untenanted"

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }

  git_library_persistence_settings {
    git_credential_id  = data.octopusdeploy_git_credentials.gitcredential.git_credentials[0].id
    url                = "http://gitea:3000/octopuscac/azure_web_app_cac.git"
    base_path          = ".octopus/project"
    default_branch     = "main"
    protected_branches = []
  }
}

resource "octopusdeploy_variable" "cloud_discovery" {
  owner_id = octopusdeploy_project.project.id
  type     = "AzureAccount"
  name     = "Octopus.Azure.Account"
  value    = data.octopusdeploy_accounts.azure.accounts[0].id
}

 resource "octopusdeploy_deployment_process" "deployment_process" {
   project_id = octopusdeploy_project.project.id

   lifecycle {
     ignore_changes = [
       step,
     ]
   }

   step {
     condition           = "Success"
     name                = "Create Web App"
     package_requirement = "LetOctopusDecide"
     start_trigger       = "StartAfterPrevious"

     action {
       action_type                        = "Octopus.AzurePowerShell"
       name                               = "Create Web App"
       condition                          = "Success"
       run_on_server                      = true
       is_disabled                        = false
       can_be_used_for_project_versioning = true
       is_required                        = false
       worker_pool_id                     = "${data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id}"
       properties                         = {
         "Octopus.Action.Script.ScriptSource" = "Inline"
         "Octopus.Action.Script.Syntax"       = "Bash"
         "Octopus.Action.Azure.AccountId"     = data.octopusdeploy_accounts.azure.accounts[0].id
         "Octopus.Action.Script.ScriptBody"   = file("../scripts/create_web_app.sh")
         "OctopusUseBundledTooling"           = "False"
       }

       environments          = []
       excluded_environments = [data.octopusdeploy_environments.security.environments[0].id]
       channels              = []
       tenant_tags           = []
       features              = []
     }

     properties   = {}
     target_roles = []
   }

   step {
     condition           = "Success"
     name                = "Deploy Web App"
     package_requirement = "LetOctopusDecide"
     start_trigger       = "StartAfterPrevious"

     action {
       action_type                        = "Octopus.AzureAppService"
       name                               = "Deploy Web App"
       notes                              = "Deploys the Azure Web App from a Docker image."
       condition                          = "Success"
       run_on_server                      = true
       is_disabled                        = false
       can_be_used_for_project_versioning = true
       is_required                        = false
       worker_pool_id                     = "${data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id}"
       properties                         = {
         "OctopusUseBundledTooling"                  = "False"
         "Octopus.Action.Azure.DeploymentType"       = "Container"
         "Octopus.Action.Package.DownloadOnTentacle" = "False"
       }
       environments          = []
       excluded_environments = [data.octopusdeploy_environments.security.environments[0].id]
       channels              = []
       tenant_tags           = []

       primary_package {
         package_id           = "#{Azure.WebApp.PackageId}"
         acquisition_location = "NotAcquired"
         feed_id              = data.octopusdeploy_feeds.docker.feeds[0].id
         properties           = { SelectionMode = "immediate" }
       }

       features = [
         "Octopus.Features.JsonConfigurationVariables",
         "Octopus.Features.ConfigurationTransforms",
         "Octopus.Features.SubstituteInFiles"
       ]
     }

     properties   = {}
     target_roles = ["octopub-webapp-cac"]
   }
   step {
     condition           = "Success"
     name                = "End-to-end Test with Cypress"
     package_requirement = "LetOctopusDecide"
     start_trigger       = "StartAfterPrevious"

     action {
       action_type                        = "Octopus.Script"
       name                               = "End-to-end Test with Cypress"
       condition                          = "Success"
       run_on_server                      = true
       is_disabled                        = false
       can_be_used_for_project_versioning = true
       is_required                        = false
       worker_pool_id                     = "${data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id}"
       properties                         = {
         "Octopus.Action.Script.ScriptBody"   = file("../scripts/cypress_test.sh")
         "OctopusUseBundledTooling"           = "False"
         "Octopus.Action.Script.ScriptSource" = "Inline"
         "Octopus.Action.Script.Syntax"       = "Bash"
       }

       environments          = []
       excluded_environments = [data.octopusdeploy_environments.security.environments[0].id]
       channels              = []
       tenant_tags           = []

       package {
         name                      = "octopub-cypress"
         package_id                = "com.octopus:octopub-cypress"
         acquisition_location      = "Server"
         extract_during_deployment = false
         feed_id                   = data.octopusdeploy_feeds.maven.feeds[0].id
         properties                = { Extract = "True", Purpose = "", SelectionMode = "immediate" }
       }
       features = []
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
       condition                          = "Success"
       run_on_server                      = true
       is_disabled                        = false
       can_be_used_for_project_versioning = true
       is_required                        = true
       worker_pool_id                     = "${data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id}"
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
         package_id                = "com.octopus:octopub-sbom"
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

resource "octopusdeploy_runbook" "runbook_delete_web_app" {
  name                        = "Delete Web App"
  project_id                  = octopusdeploy_project.project.id
  environment_scope           = "All"
  environments                = []
  force_package_download      = false
  default_guided_failure_mode = "EnvironmentDefault"
  description                 = "WARNING: This is a destructive operation!\nDelete the resource group holding the web app."
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

resource "octopusdeploy_runbook_process" "delete_web_app" {
  runbook_id = octopusdeploy_runbook.runbook_delete_web_app.id

  step {
    condition           = "Success"
    name                = "Delete Web App"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.AzurePowerShell"
      name                               = "Delete Web App"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = true
      is_required                        = false
      worker_pool_id                     = "${data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id}"
      properties                         = {
        "Octopus.Action.Script.ScriptSource" = "Inline"
        "Octopus.Action.Script.Syntax"       = "Bash"
        "Octopus.Action.Azure.AccountId"     = data.octopusdeploy_accounts.azure.accounts[0].id
        "Octopus.Action.Script.ScriptBody"   = <<EOT
RESOURCE_NAME=#{Octopus.Space.Name | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}-#{Octopus.Project.Name | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}-#{Octopus.Environment.Name | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}
EXISTING_RG=$(az group list --query "[?name=='$${RESOURCE_NAME}-rg']")
LENGTH=$(echo $${EXISTING_RG} | jq '. | length')

if [[ $LENGTH != "0" ]]
then
  az group delete -n $${RESOURCE_NAME}-rg --yes
fi
EOT
        "OctopusUseBundledTooling"           = "False"
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

resource "octopusdeploy_runbook" "runbook_get_web_app_logs" {
  name                        = "Get Web App Logs"
  project_id                  = octopusdeploy_project.project.id
  environment_scope           = "All"
  environments                = []
  force_package_download      = false
  default_guided_failure_mode = "EnvironmentDefault"
  description                 = "Get the the web app logs. This runbook is non-destructive and can be run at any time."
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

resource "octopusdeploy_runbook_process" "get_web_app_logs" {
  runbook_id = octopusdeploy_runbook.runbook_get_web_app_logs.id

  step {
    condition           = "Success"
    name                = "Get Web App Logs"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.AzurePowerShell"
      name                               = "Get Web App Logs"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = true
      is_required                        = false
      worker_pool_id                     = data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id
      properties                         = {
        "Octopus.Action.Script.ScriptSource" = "Inline"
        "Octopus.Action.Script.Syntax"       = "Bash"
        "Octopus.Action.Azure.AccountId"     = data.octopusdeploy_accounts.azure.accounts[0].id
        "Octopus.Action.Script.ScriptBody"   = <<EOT
RESOURCE_NAME=#{Octopus.Space.Name | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}-#{Octopus.Project.Name | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}-#{Octopus.Environment.Name | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}
EXISTING_RG=$(az group list --query "[?name=='$${RESOURCE_NAME}-rg']")
LENGTH=$(echo $${EXISTING_RG} | jq '. | length')

if [[ $LENGTH != "0" ]]
then
  max_retry=6
  counter=0
  until timeout 30 az webapp log download --name $${RESOURCE_NAME}-wa --resource-group $${RESOURCE_NAME}-rg 2>&1
  do
     sleep 10
     [[ counter -eq $max_retry ]] && echo "Failed!" && exit 1
     echo "Trying again. Try #$counter"
     ((counter++))
  done

  new_octopusartifact "$${PWD}/webapp_logs.zip" "webapp_logs.zip"
fi
EOT
        "OctopusUseBundledTooling"           = "False"
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