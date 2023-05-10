terraform {
  required_providers {
    octopusdeploy = { source = "OctopusDeployLabs/octopusdeploy", version = "0.12.1" }
  }
}

locals {
  # This value is used in a few places, like the deployment name. It is the name of the Docker image, minus the repo, lowercase, and with
  # special chars removed.
  app_name = "#{Octopus.Action[Deploy App].Package[service].PackageId | Replace \"^.*/\" \"\" | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}"
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

data "octopusdeploy_library_variable_sets" "octopus_server" {
  partial_name = "Octopus Server"
  skip         = 0
  take         = 1
}

data "octopusdeploy_library_variable_sets" "variable" {
  partial_name = "This Instance"
  skip         = 0
  take         = 1
}

data "octopusdeploy_environments" "production" {
  partial_name = "Production"
  skip         = 0
  take         = 1
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

resource "octopusdeploy_variable" "k8s_image" {
  owner_id     = octopusdeploy_project.project_ad_service.id
  value        = "octopussamples/adservice"
  name         = "Kubernetes.Application.Image"
  type         = "String"
  description  = "The Docker image deployed by this application."
  is_sensitive = false
}

resource "octopusdeploy_variable" "k8s_env_vars" {
  owner_id     = octopusdeploy_project.project_ad_service.id
  value        = "KEY1: Value1\nKEY2: Value2"
  name         = "Kubernetes.Application.EnvVars"
  type         = "String"
  description  = "Replace this variable with key value pairs that make up the microservice env vars."
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
    name                = "Deploy Env Var ConfigMap"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.KubernetesDeployRawYaml"
      name                               = "Deploy Env Var ConfigMap"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = false
      worker_pool_id                     = ""
      worker_pool_variable               = ""
      properties                         = {
        "Octopus.Action.KubernetesContainers.CustomResourceYaml" = <<EOT
apiVersion: v1
kind: ConfigMap
metadata:
  name: "${local.app_name}#{unless Octopus.Release.Channel.Name == \"Mainline\"}-#{Octopus.Release.Channel.Name}#{/unless}"
  namespace: "#{Octopus.Space.Name | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}-#{Kubernetes.Application.Group}-#{Octopus.Environment.Name | Replace \" .*\" \"\" | ToLower}"
data:
#{Kubernetes.Application.EnvVars | Indent 2}
EOT
        "Octopus.Action.Script.ScriptSource"                     = "Inline"
        "Octopus.Action.KubernetesContainers.Namespace"          = "#{Octopus.Space.Name | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}-#{Kubernetes.Application.Group}-#{Octopus.Environment.Name | Replace \" .*\" \"\" | ToLower}"
      }
      environments          = []
      excluded_environments = []
      channels              = []
      tenant_tags           = []
      features              = []
    }

    properties   = {}
    target_roles = ["k8s"]
  }

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
        "Octopus.Action.KubernetesContainers.DeploymentName"                = "${local.app_name}#{unless Octopus.Release.Channel.Name == \"Mainline\"}-#{Octopus.Release.Channel.Name}#{/unless}"
        "Octopus.Action.KubernetesContainers.PodAffinity"                   = jsonencode([])
        "Octopus.Action.KubernetesContainers.IngressAnnotations"            = jsonencode([])
        "Octopus.Action.KubernetesContainers.Containers"                    = jsonencode([
          {
            "AcquisitionLocation"    = "NotAcquired"
            "Args"                   = []
            "ConfigMapEnvFromSource" = [
              {
                "key" = "${local.app_name}#{unless Octopus.Release.Channel.Name == \"Mainline\"}-#{Octopus.Release.Channel.Name}#{/unless}"
              },
            ]
            "ConfigMapEnvironmentVariables" = []
            "EnvironmentVariables"          = [
              {
                "key"   = "PORT"
                "value" = "#{Kubernetes.Application.Port}"
              }
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
            "PackageId"                    = "#{Kubernetes.Application.Image}"
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
          "app" = "${local.app_name}"
        })
        "Octopus.Action.KubernetesContainers.PodSecurityRunAsUser"    = "1000"
        "Octopus.Action.KubernetesContainers.PodSecurityFsGroup"      = "1000"
        "Octopus.Action.KubernetesContainers.Replicas"                = "1"
        "Octopus.Action.KubernetesContainers.ServiceName"             = "${local.app_name}#{unless Octopus.Release.Channel.Name == \"Mainline\"}-#{Octopus.Release.Channel.Name}#{/unless}"
        "Octopus.Action.KubernetesContainers.LoadBalancerAnnotations" = jsonencode([])
      }

      environments          = []
      excluded_environments = ["Environments-1064", "Environments-1065"]
      channels              = []
      tenant_tags           = []

      package {
        name                      = "service"
        package_id                = "#{Kubernetes.Application.Image}"
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
  included_library_variable_sets       = [
    data.octopusdeploy_library_variable_sets.variable.library_variable_sets[0].id,
    data.octopusdeploy_library_variable_sets.octopus_server.library_variable_sets[0].id
  ]
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

resource "octopusdeploy_runbook_process" "runbook_process_k8s_describe_pod" {
  runbook_id = "${octopusdeploy_runbook.runbook_k8s_describe_pod.id}"

  step {
    condition           = "Success"
    name                = "Describe Pod"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.KubernetesRunScript"
      name                               = "Describe Pod"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = false
      worker_pool_id                     = ""
      worker_pool_variable               = ""
      properties                         = {
        "Octopus.Action.Script.ScriptSource" = "Inline"
        "Octopus.Action.Script.Syntax" = "PowerShell"
        "Octopus.Action.Script.ScriptBody" = "\u003c#\n    This script provides a general purpose method for querying Kubernetes resources. It supports common operations\n    like get, describe, logs and output formats like yaml and json. Output can be captured as artifacts.\n#\u003e\n\n\u003c#\n.Description\nExecute an application, capturing the output. Based on https://stackoverflow.com/a/33652732/157605\n#\u003e\nFunction Execute-Command ($commandPath, $commandArguments)\n{\n  Write-Host \"Executing: $commandPath $($commandArguments -join \" \")\"\n  \n  Try {\n    $pinfo = New-Object System.Diagnostics.ProcessStartInfo\n    $pinfo.FileName = $commandPath\n    $pinfo.RedirectStandardError = $true\n    $pinfo.RedirectStandardOutput = $true\n    $pinfo.UseShellExecute = $false\n    $pinfo.Arguments = $commandArguments\n    $p = New-Object System.Diagnostics.Process\n    $p.StartInfo = $pinfo\n    $p.Start() | Out-Null\n    [pscustomobject]@{\n        stdout = $p.StandardOutput.ReadToEnd()\n        stderr = $p.StandardError.ReadToEnd()\n        ExitCode = $p.ExitCode\n    }\n    $p.WaitForExit()\n  }\n  Catch {\n     exit\n  }\n}\n\n\u003c#\n.Description\nFind any resource names that match a wildcard input if one was specified\n#\u003e\nfunction Get-Resources() \n{\n    $names = $OctopusParameters[\"K8SInspectNames\"] -Split \"`n\" | % {$_.Trim()}\n    \n    if ($OctopusParameters[\"K8SInspectNames\"] -match '\\*' )\n    {\n        return Execute-Command kubectl (@(\"-o\", \"json\", \"get\", $OctopusParameters[\"K8SInspectResource\"])) |\n            # Select the stdout property from the execution\n            Select-Object -ExpandProperty stdout |\n            # Convert the output from JSON\n            ConvertFrom-JSON | \n            # Get the items object from the kubectl response\n            % {if ((Get-Member -InputObject $_ -Name items).Count -ne 0) {Select-Object -InputObject $_ -ExpandProperty items} else {$_}} |\n            # Extract the name\n            % {$_.metadata.name} |\n            # Find any matching resources\n            ? {$k8sName = $_; ($names | ? {$k8sName -like $_}).Count -ne 0}\n    }\n    else\n    {\n        return $names\n    }\n}\n\n\u003c#\n.Description\nGet the kubectl arguments for a given action\n#\u003e\nfunction Get-KubectlVerb() \n{\n    switch($OctopusParameters[\"K8SInspectKubectlVerb\"])\n    {\n        \"get json\" {return ,@(\"-o\", \"json\", \"get\")}\n        \"get yaml\" {return ,@(\"-o\", \"yaml\", \"get\")}\n        \"describe\" {return ,@(\"describe\")}\n        \"logs\" {return ,@(\"logs\")}\n        \"logs tail\" {return ,@(\"logs\", \"--tail\", \"100\")}\n        \"previous logs\" {return ,@(\"logs\", \"--previous\")}\n        \"previous logs tail\" {return ,@(\"logs\", \"--previous\", \"--tail\", \"100\")}\n        default {return ,@(\"get\")}\n    }\n}\n\n\u003c#\n.Description\nGet an appropiate file extension based on the selected action\n#\u003e\nfunction Get-ArtifactExtension() \n{\n   switch($OctopusParameters[\"K8SInspectKubectlVerb\"])\n    {\n        \"get json\" {\"json\"}\n        \"get yaml\" {\"yaml\"}\n        default {\"txt\"}\n    }\n}\n\nif ($OctopusParameters[\"K8SInspectKubectlVerb\"] -like \"*logs*\") \n{\n    if ( -not @($OctopusParameters[\"K8SInspectResource\"]) -like \"pod*\")\n    {\n        Write-Error \"Logs can only be returned for pods, not $($OctopusParameters[\"K8SInspectResource\"])\"\n    }\n    else\n    {\n        Execute-Command kubectl (@(\"-o\", \"json\", \"get\", \"pods\") + (Get-Resources)) |\n            # Select the stdout property from the execution\n            Select-Object -ExpandProperty stdout |\n            # Convert the output from JSON\n            ConvertFrom-JSON | \n            # Get the items object from the kubectl response\n            % {if ((Get-Member -InputObject $_ -Name items).Count -ne 0) {Select-Object -InputObject $_ -ExpandProperty items} else {$_}} |\n            # Get the pod logs for each container\n            % {\n                $podDetails = $_\n                @{\n                    logs=$podDetails.spec.containers | % {$logs=\"\"} {$logs += (Select-Object -InputObject (Execute-Command kubectl ((Get-KubectlVerb) + @($podDetails.metadata.name, \"-c\", $_.name))) -ExpandProperty stdout)} {$logs}; \n                    name=$podDetails.metadata.name\n                }                \n            } |\n            # Write the output\n            % {Write-Host $_.logs; $_} |\n            # Optionally capture the artifact\n            % {\n                if ($OctopusParameters[\"K8SInspectCreateArtifact\"] -ieq \"true\") \n                {\n                    Set-Content -Path \"$($_.name).$(Get-ArtifactExtension)\" -Value $_.logs\n                    New-OctopusArtifact \"$($_.name).$(Get-ArtifactExtension)\"\n                }\n            }\n    }      \n}\nelse\n{\n    Execute-Command kubectl ((Get-KubectlVerb) + @($OctopusParameters[\"K8SInspectResource\"]) + (Get-Resources)) |\n        % {Select-Object -InputObject $_ -ExpandProperty stdout} |\n        % {Write-Host $_; $_} |\n        % {\n            if ($OctopusParameters[\"K8SInspectCreateArtifact\"] -ieq \"true\") \n            {\n                Set-Content -Path \"output.$(Get-ArtifactExtension)\" -Value $_\n                New-OctopusArtifact \"output.$(Get-ArtifactExtension)\"\n            }\n        }\n}\n"
        "K8SInspectNames" = "${local.app_name}#{unless Octopus.Release.Channel.Name == \"Mainline\"}-#{Octopus.Release.Channel.Name}#{/unless}*"
        "K8SInspectKubectlVerb" = "describe"
        "K8SInspectCreateArtifact" = "False"
        "K8SInspectResource" = "pod"
        "Octopus.Action.KubernetesContainers.Namespace" = "#{Octopus.Space.Name | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}-#{Kubernetes.Application.Group}-#{Octopus.Environment.Name | Replace \" .*\" \"\" | ToLower}"
      }
      environments                       = []
      excluded_environments              = []
      channels                           = []
      tenant_tags                        = []
      features                           = []
    }

    properties   = {}
    target_roles = ["k8s"]
  }
}

resource "octopusdeploy_runbook" "runbook_k8s_describe_pod" {
  name                        = "Describe Pod"
  project_id                  = "${octopusdeploy_project.project_ad_service.id}"
  environment_scope           = "All"
  environments                = []
  force_package_download      = false
  default_guided_failure_mode = "EnvironmentDefault"
  description                 = ""
  multi_tenancy_mode          = "Untenanted"

  retention_policy {
    quantity_to_keep    = 100
    should_keep_forever = false
  }

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }
}

resource "octopusdeploy_runbook_process" "runbook_process_k8s_pod_logs" {
  runbook_id = octopusdeploy_runbook.runbook_k8s_pod_logs.id

  step {
    condition           = "Success"
    name                = "Describe Pod"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.KubernetesRunScript"
      name                               = "Describe Pod"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = false
      worker_pool_id                     = ""
      worker_pool_variable               = ""
      properties                         = {
        "Octopus.Action.Script.ScriptSource" = "Inline"
        "Octopus.Action.Script.Syntax" = "PowerShell"
        "Octopus.Action.Script.ScriptBody" = "\u003c#\n    This script provides a general purpose method for querying Kubernetes resources. It supports common operations\n    like get, describe, logs and output formats like yaml and json. Output can be captured as artifacts.\n#\u003e\n\n\u003c#\n.Description\nExecute an application, capturing the output. Based on https://stackoverflow.com/a/33652732/157605\n#\u003e\nFunction Execute-Command ($commandPath, $commandArguments)\n{\n  Write-Host \"Executing: $commandPath $($commandArguments -join \" \")\"\n  \n  Try {\n    $pinfo = New-Object System.Diagnostics.ProcessStartInfo\n    $pinfo.FileName = $commandPath\n    $pinfo.RedirectStandardError = $true\n    $pinfo.RedirectStandardOutput = $true\n    $pinfo.UseShellExecute = $false\n    $pinfo.Arguments = $commandArguments\n    $p = New-Object System.Diagnostics.Process\n    $p.StartInfo = $pinfo\n    $p.Start() | Out-Null\n    [pscustomobject]@{\n        stdout = $p.StandardOutput.ReadToEnd()\n        stderr = $p.StandardError.ReadToEnd()\n        ExitCode = $p.ExitCode\n    }\n    $p.WaitForExit()\n  }\n  Catch {\n     exit\n  }\n}\n\n\u003c#\n.Description\nFind any resource names that match a wildcard input if one was specified\n#\u003e\nfunction Get-Resources() \n{\n    $names = $OctopusParameters[\"K8SInspectNames\"] -Split \"`n\" | % {$_.Trim()}\n    \n    if ($OctopusParameters[\"K8SInspectNames\"] -match '\\*' )\n    {\n        return Execute-Command kubectl (@(\"-o\", \"json\", \"get\", $OctopusParameters[\"K8SInspectResource\"])) |\n            # Select the stdout property from the execution\n            Select-Object -ExpandProperty stdout |\n            # Convert the output from JSON\n            ConvertFrom-JSON | \n            # Get the items object from the kubectl response\n            % {if ((Get-Member -InputObject $_ -Name items).Count -ne 0) {Select-Object -InputObject $_ -ExpandProperty items} else {$_}} |\n            # Extract the name\n            % {$_.metadata.name} |\n            # Find any matching resources\n            ? {$k8sName = $_; ($names | ? {$k8sName -like $_}).Count -ne 0}\n    }\n    else\n    {\n        return $names\n    }\n}\n\n\u003c#\n.Description\nGet the kubectl arguments for a given action\n#\u003e\nfunction Get-KubectlVerb() \n{\n    switch($OctopusParameters[\"K8SInspectKubectlVerb\"])\n    {\n        \"get json\" {return ,@(\"-o\", \"json\", \"get\")}\n        \"get yaml\" {return ,@(\"-o\", \"yaml\", \"get\")}\n        \"describe\" {return ,@(\"describe\")}\n        \"logs\" {return ,@(\"logs\")}\n        \"logs tail\" {return ,@(\"logs\", \"--tail\", \"100\")}\n        \"previous logs\" {return ,@(\"logs\", \"--previous\")}\n        \"previous logs tail\" {return ,@(\"logs\", \"--previous\", \"--tail\", \"100\")}\n        default {return ,@(\"get\")}\n    }\n}\n\n\u003c#\n.Description\nGet an appropiate file extension based on the selected action\n#\u003e\nfunction Get-ArtifactExtension() \n{\n   switch($OctopusParameters[\"K8SInspectKubectlVerb\"])\n    {\n        \"get json\" {\"json\"}\n        \"get yaml\" {\"yaml\"}\n        default {\"txt\"}\n    }\n}\n\nif ($OctopusParameters[\"K8SInspectKubectlVerb\"] -like \"*logs*\") \n{\n    if ( -not @($OctopusParameters[\"K8SInspectResource\"]) -like \"pod*\")\n    {\n        Write-Error \"Logs can only be returned for pods, not $($OctopusParameters[\"K8SInspectResource\"])\"\n    }\n    else\n    {\n        Execute-Command kubectl (@(\"-o\", \"json\", \"get\", \"pods\") + (Get-Resources)) |\n            # Select the stdout property from the execution\n            Select-Object -ExpandProperty stdout |\n            # Convert the output from JSON\n            ConvertFrom-JSON | \n            # Get the items object from the kubectl response\n            % {if ((Get-Member -InputObject $_ -Name items).Count -ne 0) {Select-Object -InputObject $_ -ExpandProperty items} else {$_}} |\n            # Get the pod logs for each container\n            % {\n                $podDetails = $_\n                @{\n                    logs=$podDetails.spec.containers | % {$logs=\"\"} {$logs += (Select-Object -InputObject (Execute-Command kubectl ((Get-KubectlVerb) + @($podDetails.metadata.name, \"-c\", $_.name))) -ExpandProperty stdout)} {$logs}; \n                    name=$podDetails.metadata.name\n                }                \n            } |\n            # Write the output\n            % {Write-Host $_.logs; $_} |\n            # Optionally capture the artifact\n            % {\n                if ($OctopusParameters[\"K8SInspectCreateArtifact\"] -ieq \"true\") \n                {\n                    Set-Content -Path \"$($_.name).$(Get-ArtifactExtension)\" -Value $_.logs\n                    New-OctopusArtifact \"$($_.name).$(Get-ArtifactExtension)\"\n                }\n            }\n    }      \n}\nelse\n{\n    Execute-Command kubectl ((Get-KubectlVerb) + @($OctopusParameters[\"K8SInspectResource\"]) + (Get-Resources)) |\n        % {Select-Object -InputObject $_ -ExpandProperty stdout} |\n        % {Write-Host $_; $_} |\n        % {\n            if ($OctopusParameters[\"K8SInspectCreateArtifact\"] -ieq \"true\") \n            {\n                Set-Content -Path \"output.$(Get-ArtifactExtension)\" -Value $_\n                New-OctopusArtifact \"output.$(Get-ArtifactExtension)\"\n            }\n        }\n}\n"
        "K8SInspectNames" = "${local.app_name}#{unless Octopus.Release.Channel.Name == \"Mainline\"}-#{Octopus.Release.Channel.Name}#{/unless}*"
        "K8SInspectKubectlVerb" = "logs"
        "K8SInspectCreateArtifact" = "False"
        "K8SInspectResource" = "pod"
        "Octopus.Action.KubernetesContainers.Namespace" = "#{Octopus.Space.Name | Replace \"[^A-Za-z0-9]\" \"-\" | ToLower}-#{Kubernetes.Application.Group}-#{Octopus.Environment.Name | Replace \" .*\" \"\" | ToLower}"
      }
      environments                       = []
      excluded_environments              = []
      channels                           = []
      tenant_tags                        = []
      features                           = []
    }

    properties   = {}
    target_roles = ["k8s"]
  }
}

resource "octopusdeploy_runbook" "runbook_k8s_pod_logs" {
  name                        = "Pod Logs"
  project_id                  = "${octopusdeploy_project.project_ad_service.id}"
  environment_scope           = "All"
  environments                = []
  force_package_download      = false
  default_guided_failure_mode = "EnvironmentDefault"
  description                 = ""
  multi_tenancy_mode          = "Untenanted"

  retention_policy {
    quantity_to_keep    = 100
    should_keep_forever = false
  }

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }
}

resource "octopusdeploy_runbook" "create_incident_channel" {
  name                        = "Create Incident Channel"
  project_id                  = octopusdeploy_project.project_ad_service.id
  environment_scope           = "Specified"
  environments                = [data.octopusdeploy_environments.production.environments[0].id]
  force_package_download      = false
  default_guided_failure_mode = "EnvironmentDefault"
  description                 = "Create an incident channel to support production issues with this app."
  multi_tenancy_mode          = "Untenanted"

  retention_policy {
    quantity_to_keep    = 100
    should_keep_forever = false
  }

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }
}

resource "octopusdeploy_runbook_process" "create_incident_channel" {
  runbook_id = octopusdeploy_runbook.create_incident_channel.id

  step {
    condition           = "Success"
    name                = "Create Incident Channel"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {

      action_type                        = "Octopus.Script"
      name                               = "Create Incident Channel"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = true
      worker_pool_id                     = data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id
      properties                         = {
        "Octopus.Action.Script.ScriptSource" = "Inline"
        "Octopus.Action.Script.ScriptBody"   = file("../../scripts/create_channel.py")
        "Octopus.Action.Script.Syntax"       = "Python"
      }


      environments          = []
      excluded_environments = []
      channels              = []
      tenant_tags           = []
      features              = []
    }

    properties   = {}
    target_roles = []
  }
}