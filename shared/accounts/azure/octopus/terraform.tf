variable "azure_application_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure application ID."
}

variable "azure_subscription_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure subscription ID."
}

variable "azure_password" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The Azure password."
}

variable "azure_tenant_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure tenant ID."
}

resource "octopusdeploy_azure_service_principal" "account_azure" {
  description                       = "Azure Account"
  name                              = "Azure"
  environments                      = null
  tenant_tags                       = ["tenant_type/regional"]
  tenants                           = null
  tenanted_deployment_participation = "TenantedOrUntenanted"
  application_id                    = var.azure_application_id
  password                          = var.azure_password
  subscription_id                   = var.azure_subscription_id
  tenant_id                         = var.azure_tenant_id
}