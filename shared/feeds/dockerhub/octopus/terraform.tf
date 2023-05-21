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

resource "octopusdeploy_docker_container_registry" "feed_docker" {
  name                                 = "Docker"
  api_version                          = "v2"
  feed_uri                             = "https://index.docker.io"
  package_acquisition_location_options = ["ExecutionTarget", "NotAcquired"]
  username                             = var.docker_username
  password                             = var.docker_password
}