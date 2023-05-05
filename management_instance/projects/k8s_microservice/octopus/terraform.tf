terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.0" }
  }
}

data "octopusdeploy_project_groups" "project_group_google_microservice_demo" {
  ids          = null
  partial_name = "${var.project_group_google_microservice_demo_name}"
  skip         = 0
  take         = 1
}

data "octopusdeploy_lifecycles" "lifecycle_application" {
  ids          = null
  partial_name = "Simple"
  skip         = 0
  take         = 1
}

data "octopusdeploy_feeds" "feed_docker_hub" {
  feed_type    = "Docker"
  ids          = null
  partial_name = "Docker"
  skip         = 0
  take         = 1
}

data "octopusdeploy_feeds" "maven" {
  feed_type    = "Maven"
  partial_name = "Sales Maven Feed"
  skip         = 0
  take         = 1
}

data "octopusdeploy_worker_pools" "workerpool_default" {
  name = "Default Worker Pool"
  ids  = null
  skip = 0
  take = 1
}

variable "ad_service_octopusprintvariables_1" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The value associated with the variable OctopusPrintVariables"
  default     = "False"
}

resource "octopusdeploy_variable" "k8s_application_group" {
  owner_id     = octopusdeploy_project.project_ad_service.id
  value        = "test"
  name         = "Kubernetes.Application.Group"
  type         = "String"
  description  = "The name of the application group, which is used to construct the namespace the microservices are placed into."
  is_sensitive = false
}

resource "octopusdeploy_variable" "k8s_port" {
  owner_id     = octopusdeploy_project.project_ad_service.id
  value        = "9555"
  name         = "Kubernetes.Application.Port"
  type         = "String"
  description  = "The port exposed by the application."
  is_sensitive = false
}

resource "octopusdeploy_variable" "ad_service_octopusprintvariables_1" {
  owner_id     = "${octopusdeploy_project.project_ad_service.id}"
  value        = "${var.ad_service_octopusprintvariables_1}"
  name         = "OctopusPrintVariables"
  type         = "String"
  description  = "A debug variable used to print all variables to the logs. See [here](https://octopus.com/docs/support/debug-problems-with-octopus-variables) for more information."
  is_sensitive = false
}

resource "octopusdeploy_channel" "channel__mainline" {
  name        = "Mainline"
  description = "The channel through which mainline releases are deployed"
  project_id  = "${octopusdeploy_project.project_ad_service.id}"
  is_default  = true

  rule {

    action_package {
      deployment_action = "Deploy App"
      package_reference = "service"
    }

    tag = "^$"
  }

  tenant_tags = []
  depends_on  = [octopusdeploy_deployment_process.deployment_process_project_ad_service]
}

resource "octopusdeploy_deployment_process" "deployment_process_project_ad_service" {
  project_id = "${octopusdeploy_project.project_ad_service.id}"

  step {
    condition           = "Success"
    name                = "Deploy App"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.KubernetesDeployContainers"
      name                               = "Deploy App"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = true
      is_required                        = false
      worker_pool_id                     = "${data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id}"
      properties                         = {
        "Octopus.Action.KubernetesContainers.ServiceNameType"               = "External"
        "Octopus.Action.KubernetesContainers.PersistentVolumeClaims"        = jsonencode([])
        "Octopus.Action.KubernetesContainers.DeploymentAnnotations"         = jsonencode([])
        "Octopus.Action.KubernetesContainers.TerminationGracePeriodSeconds" = "5"
        "Octopus.Action.KubernetesContainers.PodSecuritySysctls"            = jsonencode([])
        "Octopus.Action.KubernetesContainers.PodServiceAccountName"         = "default"
        "Octopus.Action.KubernetesContainers.PodSecurityRunAsNonRoot"       = "true"
        "Octopus.Action.KubernetesContainers.ServiceType"                   = "ClusterIP"
        "Octopus.Action.KubernetesContainers.DeploymentResourceType"        = "Deployment"
        "Octopus.Action.KubernetesContainers.PodSecurityRunAsGroup"         = "1000"
        "Octopus.Action.KubernetesContainers.DeploymentWait"                = "Wait"
        "Octopus.Action.KubernetesContainers.DeploymentStyle"               = "RollingUpdate"
        "Octopus.Action.KubernetesContainers.Namespace"                     = "#{Octopus.Space.Name | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}-#{Kubernetes.Application.Group}-#{Octopus.Environment.Name | Replace \" .*\" \"\" | ToLower}"
        "Octopus.Action.KubernetesContainers.PodAntiAffinity"               = jsonencode([])
        "OctopusUseBundledTooling"                                          = "False"
        "Octopus.Action.KubernetesContainers.CombinedVolumes"               = jsonencode([])
        "Octopus.Action.KubernetesContainers.NodeAffinity"                  = jsonencode([])
        "Octopus.Action.KubernetesContainers.Tolerations"                   = jsonencode([])
        "Octopus.Action.KubernetesContainers.PodAnnotations"                = jsonencode([])
        "Octopus.Action.KubernetesContainers.DeploymentName"                = "#{Octopus.Action.Package[service].PackageId | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}#{unless Octopus.Release.Channel.Name == \"Mainline\"}-#{Octopus.Release.Channel.Name}#{/unless}"
        "Octopus.Action.KubernetesContainers.PodAffinity"                   = jsonencode([])
        "Octopus.Action.KubernetesContainers.IngressAnnotations"            = jsonencode([])
        "Octopus.Action.KubernetesContainers.Containers"                    = jsonencode([
          {
            "AcquisitionLocation"           = "NotAcquired"
            "Args"                          = []
            "ConfigMapEnvFromSource"        = []
            "ConfigMapEnvironmentVariables" = []
            "EnvironmentVariables"          = [
              {
                "key"   = "PORT"
                "value" = "#{Kubernetes.Application.Port}"
              },
              {
                "key"   = "DISABLE_STATS"
                "value" = "1"
              },
              {
                "key"   = "DISABLE_TRACING"
                "value" = "1"
              },
            ]
            "FeedId"       = "${data.octopusdeploy_feeds.feed_docker_hub.feeds[0].id}"
            "IsNew"        = "true"
            "StartupProbe" = {
              "failureThreshold"    = ""
              "initialDelaySeconds" = ""
              "timeoutSeconds"      = ""
              "type"                = "\u003cnil\u003e"
              "exec"                = {
                "command" = []
              }
              "httpGet" = {
                "host"        = ""
                "httpHeaders" = []
                "path"        = ""
                "port"        = ""
                "scheme"      = ""
              }
              "periodSeconds"    = ""
              "successThreshold" = ""
              "tcpSocket"        = {
                "host" = ""
                "port" = ""
              }
            }
            "VolumeMounts"  = []
            "LivenessProbe" = {
              "timeoutSeconds" = ""
              "exec"           = {
                "command" = [
                  "/bin/grpc_health_probe",
                  "-addr=:#{Kubernetes.Application.Port}",
                ]
              }
              "successThreshold"    = ""
              "initialDelaySeconds" = "20"
              "periodSeconds"       = "15"
              "tcpSocket"           = {
                "host" = ""
                "port" = ""
              }
              "type"             = "Command"
              "failureThreshold" = ""
              "httpGet"          = {
                "port"        = ""
                "scheme"      = ""
                "host"        = ""
                "httpHeaders" = []
                "path"        = ""
              }
            }
            "Properties" = {}
            "Resources"  = {
              "limits" = {
                "nvidiaGpu"        = ""
                "amdGpu"           = ""
                "cpu"              = "300m"
                "ephemeralStorage" = ""
                "memory"           = "300Mi"
              }
              "requests" = {
                "ephemeralStorage" = ""
                "memory"           = "180Mi"
                "cpu"              = "200m"
              }
            }
            "SecretEnvironmentVariables" = []
            "SecurityContext"            = {
              "runAsUser"      = ""
              "seLinuxOptions" = {
                "type"  = ""
                "user"  = ""
                "level" = ""
                "role"  = ""
              }
              "allowPrivilegeEscalation" = "false"
              "capabilities"             = {
                "add"  = []
                "drop" = [
                  "all",
                ]
              }
              "privileged"             = "false"
              "readOnlyRootFilesystem" = "true"
              "runAsGroup"             = ""
              "runAsNonRoot"           = ""
            }
            "Name"           = "service"
            "ReadinessProbe" = {
              "exec" = {
                "command" = [
                  "/bin/grpc_health_probe",
                  "-addr=:#{Kubernetes.Application.Port}",
                ]
              }
              "initialDelaySeconds" = "20"
              "successThreshold"    = ""
              "tcpSocket"           = {
                "host" = ""
                "port" = ""
              }
              "timeoutSeconds"   = ""
              "failureThreshold" = ""
              "httpGet"          = {
                "port"        = ""
                "scheme"      = ""
                "host"        = ""
                "httpHeaders" = []
                "path"        = ""
              }
              "periodSeconds" = "15"
              "type"          = "Command"
            }
            "Command"                      = []
            "FieldRefEnvironmentVariables" = []
            "InitContainer"                = "False"
            "Lifecycle"                    = {}
            "PackageId"                    = "octopussamples/adservice"
            "Ports"                        = [
              {
                "value" = "#{Kubernetes.Application.Port}"
              },
            ]
            "SecretEnvFromSource" = []
          },
        ])
        "Octopus.Action.KubernetesContainers.DnsConfigOptions" = jsonencode([])
        "Octopus.Action.KubernetesContainers.ServicePorts"     = jsonencode([
          {
            "port"       = "#{Kubernetes.Application.Port}"
            "targetPort" = "#{Kubernetes.Application.Port}"
            "name"       = "grpc"
          },
        ])
        "Octopus.Action.KubernetesContainers.DeploymentLabels" = jsonencode({
          "app" = "#{Octopus.Action.Package[service].PackageId | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}"
        })
        "Octopus.Action.KubernetesContainers.PodSecurityRunAsUser"    = "1000"
        "Octopus.Action.KubernetesContainers.PodSecurityFsGroup"      = "1000"
        "Octopus.Action.KubernetesContainers.Replicas"                = "1"
        "Octopus.Action.KubernetesContainers.ServiceName"             = "#{Octopus.Action.Package[service].PackageId | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}#{unless Octopus.Release.Channel.Name == \"Mainline\"}-#{Octopus.Release.Channel.Name}#{/unless}"
        "Octopus.Action.KubernetesContainers.LoadBalancerAnnotations" = jsonencode([])
      }

      environments          = []
      excluded_environments = ["Environments-1064", "Environments-1065"]
      channels              = []
      tenant_tags           = []

      package {
        name                      = "service"
        package_id                = "octopussamples/adservice"
        acquisition_location      = "NotAcquired"
        extract_during_deployment = false
        feed_id                   = "${data.octopusdeploy_feeds.feed_docker_hub.feeds[0].id}"
        properties                = { Extract = "False" }
      }
      features = ["Octopus.Features.KubernetesService"]
    }

    properties   = {}
    target_roles = ["k8s"]
  }
}

variable "project_group_google_microservice_demo_name" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The name of the project group to lookup"
  default     = "Kubernetes"
}

variable "ad_service_octopusprintevaluatedvariables_1" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The value associated with the variable OctopusPrintEvaluatedVariables"
  default     = "False"
}
resource "octopusdeploy_variable" "ad_service_octopusprintevaluatedvariables_1" {
  owner_id     = "${octopusdeploy_project.project_ad_service.id}"
  value        = "${var.ad_service_octopusprintevaluatedvariables_1}"
  name         = "OctopusPrintEvaluatedVariables"
  type         = "String"
  description  = "A debug variable used to print all variables to the logs. See [here](https://octopus.com/docs/support/debug-problems-with-octopus-variables) for more information."
  is_sensitive = false
}


variable "project_k8s_microservice_template_name" {
  type        = string
  nullable    = false
  sensitive   = false
  description = "The name of the project exported from Ad Service"
  default     = "K8S Microservice Template"
}

resource "octopusdeploy_project" "project_ad_service" {
  name                                 = "${var.project_k8s_microservice_template_name}"
  auto_create_release                  = false
  default_guided_failure_mode          = "EnvironmentDefault"
  default_to_skip_if_already_installed = false
  description                          = "Deploys the ad service."
  discrete_channel_release             = false
  is_disabled                          = false
  is_version_controlled                = false
  lifecycle_id                         = "${data.octopusdeploy_lifecycles.lifecycle_application.lifecycles[0].id}"
  project_group_id                     = "${data.octopusdeploy_project_groups.project_group_google_microservice_demo.project_groups[0].id}"
  included_library_variable_sets       = []
  tenanted_deployment_participation    = "Untenanted"

  connectivity_policy {
    allow_deployments_to_no_targets = false
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "SkipUnavailableMachines"
  }

  versioning_strategy {
    template = "#{Octopus.Version.LastMajor}.#{Octopus.Version.LastMinor}.#{Octopus.Version.LastPatch}.#{Octopus.Version.NextRevision}"
  }
}

