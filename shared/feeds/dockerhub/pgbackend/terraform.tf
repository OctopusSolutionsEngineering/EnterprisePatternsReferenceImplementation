terraform {
  backend "pg" {
      conn_str = "postgres://terraform:terraform@localhost:15432/dockerhubfeed?sslmode=disable"
  }
}

terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.0" }
  }
}

provider "octopusdeploy" {
  address  = "http://localhost:18080"
  api_key  = "API-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
  space_id = "Spaces-1"
}

variable "docker_username" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "DockerHub username."
}

variable "docker_password" {
  type        = string
  nullable    = false
  sensitive   = true
  description = "DockerHub password."
}

module "octopus" {
  source = "../octopus"
  docker_username = var.docker_username
  docker_password = var.docker_password
}