terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.0" }
  }
}

variable "azure_application_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure application ID."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "azure_subscription_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure subscription ID."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "azure_password" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The Azure password."
  default     = "dummy"
}

variable "azure_tenant_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure tenant ID."
  default     = "00000000-0000-0000-0000-000000000000"
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