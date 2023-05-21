# Look up the "Simple" lifecycle that is expected to exist in the management space.
data "octopusdeploy_lifecycles" "lifecycle_simple" {
  ids          = null
  partial_name = "Simple"
  skip         = 0
  take         = 1
}

# Look up the "Docker" feed that is expected to exist in the management space.
data "octopusdeploy_feeds" "feed_docker" {
  feed_type    = "Docker"
  ids          = null
  partial_name = "Docker"
  skip         = 0
  take         = 1
}

# Look up the built-in feed automatically created with every space.
data "octopusdeploy_feeds" "feed_octopus_server__built_in_" {
  feed_type    = "BuiltIn"
  ids          = null
  partial_name = ""
  skip         = 0
  take         = 1
}

# Look up the "The Instance" library variable set that is expected to exist in the management space.
data "octopusdeploy_library_variable_sets" "variable" {
  partial_name = "This Instance"
  skip         = 0
  take         = 1
}

# Look up the "Octopus Server" library variable set that is expected to exist in the management space.
data "octopusdeploy_library_variable_sets" "octopus_server" {
  partial_name = "Octopus Server"
  skip         = 0
  take         = 1
}

# Look up the "Default Worker Pool" worker pool that is exists by default in every new space.
data "octopusdeploy_worker_pools" "workerpool_default" {
  name = "Default Worker Pool"
  ids  = null
  skip = 0
  take = 1
}

# Look up the "Export Options" library variable set. This variable set is excluded from the Terraform serialization,
# but is used in some of the management runbooks when deploying the template projects. The "Export Options"
# library variable set allows us to keep variables out of the downstream projects because it is trivial to exclude a
# library variable set from serialization. In contrast, project variables for CaC enabled projects are very difficult
# to exclude individual variables as they are automatically written to Git and any forked Git repo automatically
# inherits them.
data "octopusdeploy_library_variable_sets" "export_options" {
  partial_name = "Export Options"
  skip         = 0
  take         = 1
}

# Look up the "Development" environment that is expected to exist in the management space.
data "octopusdeploy_environments" "development" {
  ids          = []
  partial_name = "Development"
  skip         = 0
  take         = 1
}

# Look up the "Test" environment that is expected to exist in the management space.
data "octopusdeploy_environments" "test" {
  ids          = []
  partial_name = "Test"
  skip         = 0
  take         = 1
}

# Look up the "Production" environment that is expected to exist in the management space.
data "octopusdeploy_environments" "production" {
  ids          = []
  partial_name = "Production"
  skip         = 0
  take         = 1
}

# Look up the "Sync" environment that is expected to exist in the management space.
data "octopusdeploy_environments" "sync" {
  ids          = []
  partial_name = "Sync"
  skip         = 0
  take         = 1
}

# Look up the "Hello World" project group that is expected to exist in the management space.
data "octopusdeploy_project_groups" "project_group_hello_world" {
  ids          = null
  partial_name = "Hello World"
  skip         = 0
  take         = 1
}

# A variable used to change the output message.
resource "octopusdeploy_variable" "world" {
  owner_id = octopusdeploy_project.project_hello_world.id
  type     = "String"
  name     = "Hello.Target"
  value    = "World"
}

# This variable uses the convention of prefixing managed space specific variables with "Private.".
# We can then exclude these commonly named variables from the Terraform serialization process, which
# means the managed space is responsible for creating and managing this variable. This is a common pattern
# for dealing with managed space specific variables like database connection strings or other environmental
# values.
resource "octopusdeploy_variable" "from" {
  owner_id = octopusdeploy_project.project_hello_world.id
  type     = "String"
  name     = "Private.Hello.From"
  value    = "the Development space!"
}

# Secret variables must be unambiguous (i.e. only have a single value) and made available to the "Sync"
# environment. This allows the project deployment process, run in the context of the Sync environment, to
# have access to the secret variables.
# The value of these secret variables is accessed via the syntax #{Database[#{Octopus.Environment.Name}].Password}
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

# Another unambiguous secret variable scoped to the "Sync" environment.
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

# Another unambiguous secret variable scoped to the "Sync" environment.
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

# This is the Octopus project
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
    # Note here that we only include a reference to the "Export Options" library variable set if it was found. This allows us
    # to deploy this project to a space, like the "Development" space, that does not allow the name of the downstream project
    # to be customized.
    length(data.octopusdeploy_library_variable_sets.export_options.library_variable_sets) != 0 ? data.octopusdeploy_library_variable_sets.export_options.library_variable_sets[0].id : "",
  ]
  tenanted_deployment_participation = "Untenanted"

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }
}

# This is the deployment process.
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
      notes                              = "A simple script step printing the value of some variables."
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
      notes                              = "This step ensures that secret variables were correctly defined."
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
  echo "#{Database[#{Octopus.Environment.Name}].Password}" | base64 -w0
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