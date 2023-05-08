terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }
  }
}

terraform {
  backend "s3" {
  }
}

provider "octopusdeploy" {
  address  = "${var.octopus_server}"
  api_key  = "${var.octopus_apikey}"
  space_id = "${var.octopus_space_id}"
}

variable "octopus_server" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The URL of the Octopus server e.g. https://myinstance.octopus.app."
}

variable "octopus_apikey" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The API key used to access the Octopus server. See https://octopus.com/docs/octopus-rest-api/how-to-create-an-api-key for details on creating an API key."
}

variable "octopus_space_id" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The ID of the Octopus space to populate."
}

variable "k8s_cluster_url" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The K8s url"
}

variable "k8s_client_cert" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "The K8s client cert"
}

module "octopus" {
  source       = "../octopus"
  k8s_cluster_url = var.k8s_cluster_url
  k8s_client_cert = var.k8s_client_cert
}