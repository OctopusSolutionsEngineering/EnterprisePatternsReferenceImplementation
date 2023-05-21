variable "aws_access_key" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The AWS Access key."
}

variable "aws_secret_key" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The AWS Secret key."
}

resource "octopusdeploy_aws_account" "account_aws_account" {
  name                              = "AWS Account"
  description                       = ""
  environments                      = null
  tenant_tags                       = ["type/managed_instance"]
  tenants                           = null
  tenanted_deployment_participation = "TenantedOrUntenanted"
  access_key                        = var.aws_access_key
  secret_key                        = var.aws_secret_key
}