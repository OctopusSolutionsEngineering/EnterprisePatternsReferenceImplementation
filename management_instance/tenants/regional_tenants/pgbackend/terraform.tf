terraform {
  backend "pg" {
    conn_str = "postgres://terraform:terraform@localhost:15432/management_tenants?sslmode=disable"
  }
}

terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.0" }
  }
}

variable "octopus_space_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The ID of the Octopus space to populate."
  default     = "Spaces-1"
}

provider "octopusdeploy" {
  address  = "http://localhost:18080"
  api_key  = "API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  space_id = var.octopus_space_id
}

variable "america_azure_application_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure application ID."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "america_azure_subscription_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure subscription ID."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "america_azure_password" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The Azure password."
  default     = "dummy"
}

variable "america_azure_tenant_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure tenant ID."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "europe_azure_application_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure application ID."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "europe_azure_subscription_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure subscription ID."
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "europe_azure_password" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The Azure password."
  default     = "dummy"
}

variable "europe_azure_tenant_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The Azure tenant ID."
  default     = "00000000-0000-0000-0000-000000000000"
}

module "octopus" {
  source                        = "../octopus"
  america_azure_application_id  = var.america_azure_application_id
  america_azure_subscription_id = var.america_azure_subscription_id
  america_azure_password        = var.america_azure_password
  america_azure_tenant_id       = var.america_azure_tenant_id
  europe_azure_application_id   = var.europe_azure_application_id
  europe_azure_subscription_id  = var.europe_azure_subscription_id
  europe_azure_password         = var.europe_azure_password
  europe_azure_tenant_id        = var.europe_azure_tenant_id
}