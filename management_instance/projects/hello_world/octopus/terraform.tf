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

data "octopusdeploy_library_variable_sets" "export_options" {
  partial_name = "Export Options"
  skip         = 0
  take         = 1
}

data "octopusdeploy_environments" "development" {
  ids          = []
  partial_name = "Development"
  skip         = 0
  take         = 1
}

data "octopusdeploy_environments" "test" {
  ids          = []
  partial_name = "Test"
  skip         = 0
  take         = 1
}

data "octopusdeploy_environments" "production" {
  ids          = []
  partial_name = "Production"
  skip         = 0
  take         = 1
}


data "octopusdeploy_environments" "sync" {
  ids          = []
  partial_name = "Sync"
  skip         = 0
  take         = 1
}

resource "octopusdeploy_variable" "world" {
  owner_id = octopusdeploy_project.project_hello_world.id
  type     = "String"
  name     = "Hello.Target"
  value    = "World"
}

resource "octopusdeploy_variable" "from" {
  owner_id = octopusdeploy_project.project_hello_world.id
  type     = "String"
  name     = "Private.Hello.From"
  value    = "the Development space!"
}

# Secret variables can not be scoped if they are to be deployed to downstream environments
resource "octopusdeploy_variable" "db_password_dev" {
  owner_id        = octopusdeploy_project.project_hello_world.id
  type            = "Sensitive"
  name            = "Database[Development].Password"
  is_sensitive    = true
  sensitive_value = "DevelopmentPassword"

  scope {
    environments = [
      data.octopusdeploy_environments.development.environments[0].id,
      data.octopusdeploy_environments.sync.environments[0].id,
    ]
  }
}

resource "octopusdeploy_variable" "db_password_test" {
  owner_id        = octopusdeploy_project.project_hello_world.id
  type            = "Sensitive"
  name            = "Database[Test].Password"
  is_sensitive    = true
  sensitive_value = "PasswordTest"

  scope {
    environments = [
      data.octopusdeploy_environments.test.environments[0].id,
      data.octopusdeploy_environments.sync.environments[0].id,
    ]
  }
}

resource "octopusdeploy_variable" "db_password_production" {
  owner_id        = octopusdeploy_project.project_hello_world.id
  type            = "Sensitive"
  name            = "Database[Production].Password"
  is_sensitive    = true
  sensitive_value = "PasswordProduction"

  scope {
    environments = [
      data.octopusdeploy_environments.production.environments[0].id,
      data.octopusdeploy_environments.sync.environments[0].id,
    ]
  }
}

resource "octopusdeploy_deployment_process" "deployment_process_project_hello_world" {
  project_id = octopusdeploy_project.project_hello_world.id

  step {
    condition           = "Success"
    name                = "Hello world"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "Hello world"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = true
      worker_pool_id                     = data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id
      properties                         = {
        "Octopus.Action.Script.ScriptSource" = "Inline"
        "Octopus.Action.Script.ScriptBody"   = "echo 'Hello #{Hello.Target} from #{Private.Hello.From}'"
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

  step {
    condition           = "Success"
    name                = "Secret Scoped Variable Test"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "Secret Scoped Variable Test"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = true
      worker_pool_id                     = data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id
      properties                         = {
        "Octopus.Action.Script.ScriptSource" = "Inline"
        "Octopus.Action.Script.ScriptBody"   = <<EOT
if [[ "#{Database[#{Octopus.Environment.Name}].Password}" != "##{Database[#{Octopus.Environment.Name}].Password}" ]]
then
  echo "The secret value was successfully exported."
  echo "The base 64 encoded password (because raw passwords are masked):"
  echo "$${PASSWORD}" | base64 -w0
else
  echo "The secret value was not successfully exported."
fi
EOT
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
  included_library_variable_sets       = [
    data.octopusdeploy_library_variable_sets.variable.library_variable_sets[0].id,
    data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].id,
    length(data.octopusdeploy_library_variable_sets.export_options.library_variable_sets) != 0 ? data.octopusdeploy_library_variable_sets.export_options.library_variable_sets[0].id : "",
  ]
  tenanted_deployment_participation = "Untenanted"

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }
}