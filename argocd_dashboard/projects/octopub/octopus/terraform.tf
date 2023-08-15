# Look up the "Simple" lifecycle that is expected to exist in the management space.
data "octopusdeploy_lifecycles" "lifecycle_simple" {
  ids          = null
  partial_name = "Simple"
  skip         = 0
  take         = 1
}

data "octopusdeploy_lifecycles" "argocd" {
  ids          = null
  partial_name = "ArgoCD Overview"
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

# Look up the "Default Worker Pool" worker pool that is exists by default in every new space.
data "octopusdeploy_worker_pools" "workerpool_default" {
  name = "Default Worker Pool"
  ids  = null
  skip = 0
  take = 1
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

data "octopusdeploy_project_groups" "project_group_overview_dashboard" {
  ids          = null
  partial_name = "Scenario 1: Overview Dashboard"
  skip         = 0
  take         = 1
}

data "octopusdeploy_project_groups" "project_group_environment_progression" {
  ids          = null
  partial_name = "Scenario 2: Environment Progression"
  skip         = 0
  take         = 1
}

data "octopusdeploy_project_groups" "project_group_platform_engineering" {
  ids          = null
  partial_name = "Scenario 3: Platform Engineering"
  skip         = 0
  take         = 1
}