resource "octopusdeploy_user_role" "user_role" {
  can_be_deleted                = true
  description                   = "Grants the ability to edit project variables."
  granted_space_permissions     = ["VariableEdit", "VariableView"]
  granted_system_permissions    = []
  name                          = "Variable editor"
  space_permission_descriptions = []
}

resource "octopusdeploy_user_role" "viewer" {
  can_be_deleted            = true
  description               = "Grants read-only view to space resources."
  granted_space_permissions = [
    "AccountView", "ActionTemplateView", "ArtifactView", "CertificateView", "DeploymentView", "EnvironmentView",
    "EventView", "FeedView", "GitCredentialView", "InsightsReportView", "InterruptionView", "LibraryVariableSetView",
    "LifecycleView", "MachinePolicyView", "MachineView", "ProcessView", "ProjectGroupView", "ProjectView", "ProxyView",
    "ReleaseView", "RunbookRunView", "RunbookView", "SubscriptionView", "TaskView", "TeamView", "TenantView",
    "TriggerView", "VariableView", "VariableViewUnscoped", "WorkerView"
  ]
  granted_system_permissions    = []
  name                          = "Read-Only"
  space_permission_descriptions = []
}

resource "octopusdeploy_user_role" "task_canceller" {
  can_be_deleted            = true
  description               = "Grants the ability to cancel tasks."
  granted_space_permissions = [
    "TaskCancel"
  ]
  granted_system_permissions    = []
  name                          = "Task Cancel"
  space_permission_descriptions = []
}

resource "octopusdeploy_user" "user" {
  display_name  = "Editor"
  email_address = "editor@example.org"
  is_active     = true
  is_service    = false
  password      = "Password01!"
  username      = "editor"
}

resource "octopusdeploy_team" "editors" {
  name  = "Editors"
  users = [octopusdeploy_user.user.id]
}
