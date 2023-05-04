terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.0" }
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

data "octopusdeploy_library_variable_sets" "variable" {
  partial_name = "This Instance"
  skip         = 0
  take         = 1
}

data "octopusdeploy_library_variable_sets" "octopus_server" {
  partial_name = "Octopus Server"
  skip         = 0
  take         = 1
}

data "octopusdeploy_worker_pools" "workerpool_default" {
  name = "Default Worker Pool"
  ids  = null
  skip = 0
  take = 1
}

resource "octopusdeploy_variable" "world" {
  owner_id = octopusdeploy_project.project_hello_world.id
  type     = "String"
  name     = "Hello.Target"
  value    = "World"
}

resource "octopusdeploy_deployment_process" "deployment_process_project_hello_world" {
  project_id = octopusdeploy_project.project_hello_world.id

  lifecycle {
    ignore_changes = [
      step,
    ]
  }

  step {
    condition           = "Success"
    name                = "Hello world (using Bash)"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "Hello world (using Bash)"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = true
      worker_pool_id                     = "${data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id}"
      properties                         = {
        "Octopus.Action.Script.ScriptSource" = "Inline"
        "Octopus.Action.Script.ScriptBody"   = "echo 'Hello #{Hello.Target}, using Bash'\n\n#TODO: Experiment with steps of your own :)\n\necho '[Learn more about the types of steps available in Octopus](https://oc.to/OnboardingAddStepsLearnMore)'"
        "Octopus.Action.Script.Syntax"       = "Bash"
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

data "octopusdeploy_project_groups" "project_group_hello_world" {
  ids          = null
  partial_name = "Hello World"
  skip         = 0
  take         = 1
}

resource "octopusdeploy_project" "project_hello_world" {
  name                                 = "Hello World"
  description                          = "This project is initially created by Terraform and is then able to be updated in the Octopus UI, serialized to Terraform again with octoterra, and deployed to managed spaces."
  auto_create_release                  = false
  default_guided_failure_mode          = "EnvironmentDefault"
  default_to_skip_if_already_installed = false
  discrete_channel_release             = false
  is_disabled                          = false
  is_version_controlled                = false
  lifecycle_id                         = data.octopusdeploy_lifecycles.lifecycle_simple.lifecycles[0].id
  project_group_id                     = data.octopusdeploy_project_groups.project_group_hello_world.project_groups[0].id
  included_library_variable_sets       = [data.octopusdeploy_library_variable_sets.variable.library_variable_sets[0].id, data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].id]
  tenanted_deployment_participation    = "Untenanted"

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }
}