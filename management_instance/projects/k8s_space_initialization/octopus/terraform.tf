terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }
  }
}

data "octopusdeploy_lifecycles" "lifecycle_simple" {
  ids          = null
  partial_name = "Simple"
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

data "octopusdeploy_feeds" "feed_octopus_server__built_in_" {
  feed_type    = "BuiltIn"
  ids          = null
  partial_name = ""
  skip         = 0
  take         = 1
}

data "octopusdeploy_library_variable_sets" "octopus_server" {
  partial_name = "Octopus Server"
  skip         = 0
  take         = 1
}

data "octopusdeploy_library_variable_sets" "kubernetes" {
  partial_name = "Kubernetes"
  skip         = 0
  take         = 1
}

data "octopusdeploy_project_groups" "project_group_k8s" {
  ids          = null
  partial_name = "Kubernetes"
  skip         = 0
  take         = 1
}

data "octopusdeploy_worker_pools" "workerpool_default" {
  name = "Default Worker Pool"
  ids  = null
  skip = 0
  take = 1
}

data "octopusdeploy_environments" "sync" {
  ids          = []
  partial_name = "Sync"
  skip         = 0
  take         = 1
}

resource "octopusdeploy_project" "project_hello_world" {
  # We want this project to be sorted higher than the template projects, so start with an underscore
  name                                 = "__ Initialize Space for Kubernetes"
  description                          = "This project is used to populate a space with any common kubernetes resources."
  auto_create_release                  = false
  default_guided_failure_mode          = "EnvironmentDefault"
  default_to_skip_if_already_installed = false
  discrete_channel_release             = false
  is_disabled                          = false
  is_version_controlled                = false
  lifecycle_id                         = data.octopusdeploy_lifecycles.lifecycle_simple.lifecycles[0].id
  project_group_id                     = data.octopusdeploy_project_groups.project_group_k8s.project_groups[0].id
  included_library_variable_sets       = [
    data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].id,
    data.octopusdeploy_library_variable_sets.kubernetes.library_variable_sets[0].id
  ]
  tenanted_deployment_participation = "Untenanted"

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }
}

resource "octopusdeploy_runbook" "runbook_backend_service_deploy_project" {
  name                        = "Initialize Space"
  project_id                  = octopusdeploy_project.project_hello_world.id
  environment_scope           = "Specified"
  environments                = [data.octopusdeploy_environments.sync.environments[0].id]
  force_package_download      = false
  default_guided_failure_mode = "EnvironmentDefault"
  description                 = "This runbook initializes a space with common kubernetes resources sourced from a tenant."
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
  runbook_id = octopusdeploy_runbook.runbook_backend_service_deploy_project.id

  step {
    condition           = "Success"
    name                = "Configure the Kubernetes Target"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.TerraformApply"
      name                               = "Configure the Kubernetes Target"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = true
      is_required                        = false
      worker_pool_id                     = data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id
      properties                         = {
        "Octopus.Action.Terraform.Template"           = file("../terrform_scripts/k8s.tf")
        "Octopus.Action.Terraform.TemplateParameters" = jsonencode({
          "k8s_cluster_url"  = "#{Tenant.K8S.Url}"
          "k8s_client_cert"  = "#{Tenant.K8S.CertificateData}"
          "octopus_apikey"   = "#{ManagedTenant.Octopus.ApiKey}"
          "octopus_url"      = "#{ManagedTenant.Octopus.Server}"
          "octopus_space_id" = "#{ManagedTenant.Octopus.SpaceId}"
        })
        "Octopus.Action.Aws.AssumeRole"                         = "False"
        "Octopus.Action.Terraform.PlanJsonOutput"               = "False"
        "Octopus.Action.AwsAccount.UseInstanceRole"             = "False"
        "Octopus.Action.AwsAccount.Variable"                    = ""
        "Octopus.Action.Terraform.RunAutomaticFileSubstitution" = "True"
        "Octopus.Action.GoogleCloud.ImpersonateServiceAccount"  = "False"
        "Octopus.Action.Aws.Region"                             = ""
        "Octopus.Action.GoogleCloud.UseVMServiceAccount"        = "True"
        "OctopusUseBundledTooling"                              = "False"
        "Octopus.Action.Terraform.ManagedAccount"               = "None"
        "Octopus.Action.Script.ScriptSource"                    = "Inline"
        "Octopus.Action.Terraform.GoogleCloudAccount"           = "False"
        "Octopus.Action.Terraform.AzureAccount"                 = "False"
        "Octopus.Action.Terraform.AllowPluginDownloads"         = "True"
        "Octopus.Action.Terraform.Workspace"                    = "#{Octopus.Deployment.Tenant.Name}"
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

