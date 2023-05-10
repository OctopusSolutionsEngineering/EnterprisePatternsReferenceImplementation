terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }
  }
}

resource "octopusdeploy_user_role" "user_role" {
  can_be_deleted             = true
  description                = "Grants the ability to edit project variables."
  granted_space_permissions  = ["VariableEdit", "VariableView"]
  granted_system_permissions = []
  name                       = "Variable editor"
  space_permission_descriptions = []
}

resource "octopusdeploy_user_role" "viewer" {
  can_be_deleted             = true
  description                = "Grants read-only view to space resources."
  granted_space_permissions  = [
    "AccountView", "ActionTemplateView", "ArtifactView", "CertificateView", "DeploymentView", "EnvironmentView",
    "EventView", "FeedView", "GitCredentialView", "InsightsReportView", "InterruptionView", "LibraryVariableSetView",
    "LifecycleView", "MachinePolicyView", "MachineView", "ProcessView", "ProjectGroupView", "ProjectView", "ProxyView",
    "ReleaseView", "RunbookRunView", "RunbookView", "SubscriptionView", "TaskView", "TeamView", "TenantView",
    "TriggerView", "VariableView", "VariableViewUnscoped", "WorkerView"
  ]
  granted_system_permissions = []
  name                       = "Read-Only"
  space_permission_descriptions = []
}

resource "octopusdeploy_user" "deployer" {
  display_name  = "Deployer"
  email_address = "deployer@example.org"
  is_active     = true
  is_service    = false
  password      = "Password01!"
  username      = "deployer"

  identity {
    provider = "Octopus ID"
    claim {
      name                 = "email"
      is_identifying_claim = true
      value                = "bob.smith@example.com"
    }
    claim {
      name                 = "dn"
      is_identifying_claim = false
      value                = "Bob Smith"
    }
  }
}

resource "octopusdeploy_team" "variable_configured_project_contributors" {
  name  = "Deployers"
  users = [octopusdeploy_user.deployer.id]
}
