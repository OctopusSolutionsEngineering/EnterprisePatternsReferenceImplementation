data "octopusdeploy_machine_policies" "default_machine_policy" {
  ids          = null
  partial_name = "Default Machine Policy"
  skip         = 0
  take         = 1
}

data "octopusdeploy_environments" "development" {
  ids          = []
  partial_name = "Development"
  skip         = 0
  take         = 1
}

data "octopusdeploy_environments" "test" {
  ids          = []
  partial_name = "Test"
  skip         = 0
  take         = 1
}

data "octopusdeploy_environments" "production" {
  ids          = []
  partial_name = "Production"
  skip         = 0
  take         = 1
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

resource "octopusdeploy_certificate" "certificate_k8s_cert" {
  name                              = "K8s Client"
  certificate_data                  = var.k8s_client_cert
  password                          = "Password01!"
  environments                      = []
  notes                             = "The certificate used to authenticate with the k8s cluster"
  tenant_tags                       = []
  tenanted_deployment_participation = "Untenanted"
  tenants                           = []
}

resource "octopusdeploy_kubernetes_cluster_deployment_target" "cluster" {
  cluster_url                       = var.k8s_cluster_url
  environments                      = [
    data.octopusdeploy_environments.development.environments[0].id,
    data.octopusdeploy_environments.test.environments[0].id,
    data.octopusdeploy_environments.production.environments[0].id]
  name                              = "K8s"
  roles                             = ["k8s"]
  cluster_certificate               = ""
  machine_policy_id                 = data.octopusdeploy_machine_policies.default_machine_policy.machine_policies[0].id
  namespace                         = ""
  skip_tls_verification             = true
  tenant_tags                       = []
  tenanted_deployment_participation = "Untenanted"
  tenants                           = []
  thumbprint                        = ""
  uri                               = ""

  endpoint {
    communication_style    = "Kubernetes"
    cluster_certificate    = ""
    cluster_url            = var.k8s_cluster_url
    namespace              = ""
    skip_tls_verification  = true
    default_worker_pool_id = ""
  }

  certificate_authentication {
    client_certificate = octopusdeploy_certificate.certificate_k8s_cert.id
  }
}