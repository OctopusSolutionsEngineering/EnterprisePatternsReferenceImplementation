variable "argocd_token" {
  type      = string
  sensitive = true
}

resource "octopusdeploy_library_variable_set" "octopus_library_variable_set" {
  name = "Argo CD"
  description = "Variables related to interacting with Kubernetes"
}

resource "octopusdeploy_variable" "argocd_token" {
  owner_id        = octopusdeploy_library_variable_set.octopus_library_variable_set.id
  type            = "Sensitive"
  name            = "ArgoCD.Credentials.Token"
  is_sensitive    = true
  sensitive_value = var.argocd_token
}