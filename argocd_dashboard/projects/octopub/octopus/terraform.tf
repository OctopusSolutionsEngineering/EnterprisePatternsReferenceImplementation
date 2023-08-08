# Look up the "Simple" lifecycle that is expected to exist in the management space.
data "octopusdeploy_lifecycles" "lifecycle_simple" {
  ids          = null
  partial_name = "Simple"
  skip         = 0
  take         = 1
}

# Look up the "Docker" feed that is expected to exist in the management space.
data "octopusdeploy_feeds" "feed_docker" {
  feed_type    = "Docker"
  ids          = null
  partial_name = "Docker"
  skip         = 0
  take         = 1
}

# Look up the built-in feed automatically created with every space.
data "octopusdeploy_feeds" "feed_octopus_server__built_in_" {
  feed_type    = "BuiltIn"
  ids          = null
  partial_name = ""
  skip         = 0
  take         = 1
}

# Look up the "Default Worker Pool" worker pool that is exists by default in every new space.
data "octopusdeploy_worker_pools" "workerpool_default" {
  name = "Default Worker Pool"
  ids  = null
  skip = 0
  take = 1
}

# Look up the "Development" environment that is expected to exist in the management space.
data "octopusdeploy_environments" "development" {
  ids          = []
  partial_name = "Development"
  skip         = 0
  take         = 1
}

# Look up the "Test" environment that is expected to exist in the management space.
data "octopusdeploy_environments" "test" {
  ids          = []
  partial_name = "Test"
  skip         = 0
  take         = 1
}

# Look up the "Production" environment that is expected to exist in the management space.
data "octopusdeploy_environments" "production" {
  ids          = []
  partial_name = "Production"
  skip         = 0
  take         = 1
}

# Look up the "Hello World" project group that is expected to exist in the management space.
data "octopusdeploy_project_groups" "project_group_octopub" {
  ids          = null
  partial_name = "Octopub"
  skip         = 0
  take         = 1
}

resource "octopusdeploy_variable" "argocd_env_metadata" {
  owner_id    = octopusdeploy_project.project_octopub.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[argocd/octopub-frontend-development].Environment"
  value       = "Development"
  description = "This variable links this project's Development environment to the octopub-frontend-development ArgoCD application in the argocd namespace"
}

resource "octopusdeploy_variable" "argocd_version_metadata" {
  owner_id    = octopusdeploy_project.project_octopub.id
  type        = "String"
  name        = "Metadata.ArgoCD.Application[argocd/octopub-frontend-development].ImageForReleaseVersion"
  value       = "octopussamples/octopub-frontend"
  description = "This variable indicates that the octopussamples/octopub-frontend-microservice images deployed by the ArgoCD application is used to build the Octopus release numbers"
}

resource "octopusdeploy_variable" "argocd_git_url" {
  owner_id    = octopusdeploy_project.project_octopub.id
  type        = "String"
  name        = "Project.Git.Url"
  value       = "http://gitea:3000/octopuscac/argo_cd.git"
  description = "The git URL repo"
}

resource "octopusdeploy_variable" "argocd_git_username" {
  owner_id    = octopusdeploy_project.project_octopub.id
  type        = "String"
  name        = "Project.Git.Username"
  value       = "octopus"
  description = "The git username"
}

resource "octopusdeploy_variable" "argocd_git_password" {
  owner_id        = octopusdeploy_project.project_octopub.id
  type            = "Sensitive"
  name            = "Project.Git.Password"
  is_sensitive    = true
  sensitive_value = "Password01!"
  description     = "The git password"
}

resource "octopusdeploy_variable" "argocd_git_sourceitems" {
  owner_id    = octopusdeploy_project.project_octopub.id
  type        = "String"
  name        = "Project.Git.SourceItems"
  value       = "/argocd/octopub-frontend/overlays/development/frontend-versions.yaml"
  description = "The file that represents the release settings to be promoted between environments"
}

resource "octopusdeploy_variable" "argocd_git_destinationpath" {
  owner_id    = octopusdeploy_project.project_octopub.id
  type        = "String"
  name        = "Project.Git.DestinationPath"
  value       = "/argocd/octopub-frontend/overlays/#{Octopus.Environment.Name | ToLower}"
  description = "The directory that represents the release settings in the target environment"
}

# This is the Octopus project
resource "octopusdeploy_project" "project_octopub" {
  name                                 = "Octopub"
  description                          = "This project is used to manage the deployment of Octopub via ArgoCD."
  auto_create_release                  = false
  default_guided_failure_mode          = "EnvironmentDefault"
  default_to_skip_if_already_installed = false
  discrete_channel_release             = false
  is_disabled                          = false
  is_version_controlled                = false
  lifecycle_id                         = data.octopusdeploy_lifecycles.lifecycle_simple.lifecycles[0].id
  project_group_id                     = data.octopusdeploy_project_groups.project_group_octopub.project_groups[0].id
  included_library_variable_sets       = []
  tenanted_deployment_participation    = "Untenanted"

  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets       = false
    skip_machine_behavior           = "None"
  }
}

# This is the deployment process.
resource "octopusdeploy_deployment_process" "deployment_process_project_octopub" {
  project_id = octopusdeploy_project.project_octopub.id

  step {
    condition           = "Success"
    name                = "Tag the release"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "Tag the release"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = false
      worker_pool_id                     = data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id
      properties                         = {
        "Octopus.Action.RunOnServer"         = "true"
        "Octopus.Action.Script.ScriptSource" = "Inline"
        "Octopus.Action.Script.Syntax"       = "PowerShell"
        "Octopus.Action.Script.ScriptBody"   = "Function Invoke-Git\n{\n\t# Define parameters\n    param (\n    \t$GitRepositoryUrl,\n        $GitFolder,\n        $GitUsername,\n        $GitPassword,\n        $GitCommand,\n        $AdditionalArguments\n    )\n    \n    # Get current work folder\n    $workDirectory = Get-Location\n    \n    # Create arguments array\n    $gitArguments = @()\n    $gitArguments += $GitCommand\n    \n    # Check for url\n    if (![string]::IsNullOrWhitespace($GitRepositoryUrl))\n    {\n      # Convert url to URI object\n      $gitUri = [System.Uri]$GitRepositoryUrl\n      $gitUrl = \"{0}://{1}:{2}@{3}:{4}{5}\" -f $gitUri.Scheme, $GitUsername, $GitPassword, $gitUri.Host, $gitUri.Port, $gitUri.PathAndQuery\n      $gitArguments += $gitUrl\n\n      # Get the newly created folder name\n      $gitFolderName = $GitRepositoryUrl.SubString($GitRepositoryUrl.LastIndexOf(\"/\") + 1)\n      if ($gitFolderName.Contains(\".git\"))\n      {\n          $gitFolderName = $gitFolderName.SubString(0, $gitFolderName.IndexOf(\".\"))\n      }\n    }\n   \n    \n    # Check for additional arguments\n    if ($null -ne $AdditionalArguments)\n    {\n \t\t# Add the additional arguments\n        $gitArguments += $AdditionalArguments\n    }\n    \n    # Execute git command\n    $results = Execute-Command \"git\" $gitArguments $GitFolder\n    \n    Write-Host $results.stdout\n    Write-Host $results.stderr\n    \n    # Return the foldername\n   \treturn $gitFolderName\n}\n\n# Check to see if $IsWindows is available\nif ($null -eq $IsWindows) {\n    Write-Host \"Determining Operating System...\"\n    $IsWindows = ([System.Environment]::OSVersion.Platform -eq \"Win32NT\")\n    $IsLinux = ([System.Environment]::OSVersion.Platform -eq \"Unix\")\n}\n\nFunction Execute-Command\n{\n\tparam (\n    \t$commandPath,\n        $commandArguments,\n        $workingDir\n    )\n\n\t$gitExitCode = 0\n    $executionResults = $null\n\n  Try {\n    $pinfo = New-Object System.Diagnostics.ProcessStartInfo\n    $pinfo.FileName = $commandPath\n    $pinfo.WorkingDirectory = $workingDir\n    $pinfo.RedirectStandardError = $true\n    $pinfo.RedirectStandardOutput = $true\n    $pinfo.UseShellExecute = $false\n    $pinfo.Arguments = $commandArguments\n    $p = New-Object System.Diagnostics.Process\n    $p.StartInfo = $pinfo\n    $p.Start() | Out-Null\n    $executionResults = [pscustomobject]@{\n        stdout = $p.StandardOutput.ReadToEnd()\n        stderr = $p.StandardError.ReadToEnd()\n        ExitCode = $p.ExitCode\n    }\n    $p.WaitForExit()\n    $gitExitCode = [int]$p.ExitCode\n    \n    if ($gitExitCode -ge 2) \n    {\n\t\t# Fail the step\n        throw\n    }\n    \n    return $executionResults\n  }\n  Catch {\n    # Check exit code\n    Write-Error -Message \"$($executionResults.stderr)\" -ErrorId $gitExitCode\n    exit $gitExitCode\n  }\n\n}\n\n\n# Get variables\n$gitUrl = $OctopusParameters['Project.Git.Url']\n$gitUser = $OctopusParameters['Project.Git.Username']\n$gitPassword = $OctopusParameters['Project.Git.Password']\n$gitTag = $OctopusParameters['Octopus.Release.Number']\n\n# Clone repository\n$folderName = Invoke-Git -GitRepositoryUrl $gitUrl -GitUsername $gitUser -GitPassword $gitPassword -GitCommand \"clone\"\n\n# Set user\n$gitAuthorName = $OctopusParameters['Octopus.Deployment.CreatedBy.DisplayName']\n$gitAuthorEmail = $OctopusParameters['Octopus.Deployment.CreatedBy.EmailAddress']\n\n# Check to see if user is system\nif ([string]::IsNullOrWhitespace($gitAuthorEmail) -and $gitAuthorName -eq \"System\")\n{\n\t# Initiated by the Octopus server via automated process, put something in for the email address\n    $gitAuthorEmail = \"system@octopus.local\"\n}\n\n# Configure user information\nInvoke-Git -GitCommand \"config\" -AdditionalArguments @(\"user.name\", $gitAuthorName) -GitFolder \"$($PWD)/$($folderName)\"\nInvoke-Git -GitCommand \"config\" -AdditionalArguments @(\"user.email\", $gitAuthorEmail) -GitFolder \"$($PWD)/$($folderName)\"\n\n# Tag the repo\nInvoke-Git -GitCommand \"tag\" -AdditionalArguments @(\"-a\", $gitTag, \"-m\", \"`\"Tag from #{Octopus.Project.Name} release version #{Octopus.Release.Number}`\"\") -GitFolder \"$($PWD)/$($folderName)\"\n\n# Push the new tag\nInvoke-Git -Gitcommand \"push\" -AdditionalArguments @(\"--tags\") -GitFolder \"$($PWD)/$($folderName)\""
      }
      environments          = [data.octopusdeploy_environments.development.environments[0].id]
      excluded_environments = []
      channels              = []
      tenant_tags           = []
      features              = []
    }

    properties   = {}
    target_roles = []
  }

  step {
    condition           = "Success"
    name                = "Promote the release"
    package_requirement = "LetOctopusDecide"
    start_trigger       = "StartAfterPrevious"

    action {
      action_type                        = "Octopus.Script"
      name                               = "Promote the release"
      condition                          = "Success"
      run_on_server                      = true
      is_disabled                        = false
      can_be_used_for_project_versioning = false
      is_required                        = false
      worker_pool_id                     = data.octopusdeploy_worker_pools.workerpool_default.worker_pools[0].id
      properties                         = {
        "Octopus.Action.RunOnServer"         = "true"
        "Octopus.Action.Script.ScriptSource" = "Inline"
        "Octopus.Action.Script.Syntax"       = "PowerShell"
        "Octopus.Action.Script.ScriptBody"   = "Function Invoke-Git\n{\n\t# Define parameters\n    param (\n    \t$GitRepositoryUrl,\n        $GitFolder,\n        $GitUsername,\n        $GitPassword,\n        $GitCommand,\n        $AdditionalArguments\n    )\n    \n    # Get current work folder\n    $workDirectory = Get-Location\n\n\t# Check to see if GitFolder exists\n    if (![String]::IsNullOrWhitespace($GitFolder) -and (Test-Path -Path $GitFolder) -eq $false)\n    {\n    \t# Create the folder\n        New-Item -Path $GitFolder -ItemType \"Directory\" -Force | Out-Null\n        \n        # Set the location to the new folder\n        Set-Location -Path $GitFolder\n    }\n    \n    # Create arguments array\n    $gitArguments = @()\n    $gitArguments += $GitCommand\n    \n    # Check for url\n    if (![string]::IsNullOrWhitespace($GitRepositoryUrl))\n    {\n      # Convert url to URI object\n      $gitUri = [System.Uri]$GitRepositoryUrl\n      $gitUrl = \"{0}://{1}:{2}@{3}:{4}{5}\" -f $gitUri.Scheme, $GitUsername, $GitPassword, $gitUri.Host, $gitUri.Port, $gitUri.PathAndQuery\n      $gitArguments += $gitUrl\n\n      # Get the newly created folder name\n      $gitFolderName = $GitRepositoryUrl.SubString($GitRepositoryUrl.LastIndexOf(\"/\") + 1)\n      if ($gitFolderName.Contains(\".git\"))\n      {\n          $gitFolderName = $gitFolderName.SubString(0, $gitFolderName.IndexOf(\".\"))\n      }\n    }\n   \n    \n    # Check for additional arguments\n    if ($null -ne $AdditionalArguments)\n    {\n \t\t# Add the additional arguments\n        $gitArguments += $AdditionalArguments\n    }\n    \n    # Execute git command\n    $results = Execute-Command -commandPath \"git\" -commandArguments $gitArguments -workingDir $GitFolder\n    \n    Write-Host $results.stdout\n    Write-Host $results.stderr\n    \n    # Return the foldername\n    Set-Location -Path $workDirectory\n   \treturn Join-Path -Path $GitFolder -ChildPath $gitFolderName\n}\n\n# Check to see if $IsWindows is available\nif ($null -eq $IsWindows) {\n    Write-Host \"Determining Operating System...\"\n    $IsWindows = ([System.Environment]::OSVersion.Platform -eq \"Win32NT\")\n    $IsLinux = ([System.Environment]::OSVersion.Platform -eq \"Unix\")\n}\n\nFunction Copy-Files\n{\n\t# Define parameters\n    param (\n    \t$SourcePath,\n        $DestinationPath\n    )\n    \n    # Copy the items from source path to destination path\n    $copyArguments = @{}\n    $copyArguments.Add(\"Path\", $SourcePath)\n    $copyArguments.Add(\"Destination\", $DestinationPath)\n    \n    # Check to make sure destination exists\n    if ((Test-Path -Path $DestinationPath) -eq $false)\n    {\n    \t# Create the destination path\n        New-Item -Path $DestinationPath -ItemType \"Directory\" | Out-Null\n    }\n    \n    # Check for wildcard\n    if ($SourcePath.EndsWith(\"/*\") -or $SourcePath.EndsWith(\"\\*\"))\n    {\n\t\t# Add recurse argument\n\t\t$copyArguments.Add(\"Recurse\", $true)\n    }\n    \n    # Copy files\n    Copy-Item @copyArguments\n}\n\nFunction Execute-Command\n{\n\tparam (\n    \t$commandPath,\n        $commandArguments,\n        $workingDir\n    )\n\n\t$gitExitCode = 0\n    $executionResults = $null\n\n  Try {\n    $pinfo = New-Object System.Diagnostics.ProcessStartInfo\n    $pinfo.FileName = $commandPath\n    $pinfo.WorkingDirectory = $workingDir\n    $pinfo.RedirectStandardError = $true\n    $pinfo.RedirectStandardOutput = $true\n    $pinfo.UseShellExecute = $false\n    $pinfo.Arguments = $commandArguments\n    $p = New-Object System.Diagnostics.Process\n    $p.StartInfo = $pinfo\n    $p.Start() | Out-Null\n    $executionResults = [pscustomobject]@{\n        stdout = $p.StandardOutput.ReadToEnd()\n        stderr = $p.StandardError.ReadToEnd()\n        ExitCode = $p.ExitCode\n    }\n    $p.WaitForExit()\n    $gitExitCode = [int]$p.ExitCode\n    \n    if ($gitExitCode -ge 2) \n    {\n\t\t# Fail the step\n        throw\n    }\n    \n    return $executionResults\n  }\n  Catch {\n    # Check exit code\n    Write-Error -Message \"$($executionResults.stderr)\" -ErrorId $gitExitCode\n    exit $gitExitCode\n  }\n\n}\n\n\n# Get variables\n$gitUrl = $OctopusParameters['Project.Git.Url']\n$gitUser = $OctopusParameters['Project.Git.Username']\n$gitPassword = $OctopusParameters['Project.Git.Password']\n$sourceItems = $OctopusParameters['Project.Git.SourceItems']\n$destinationPath = $OctopusParameters['Project.Git.DestinationPath']\n$gitTag = $OctopusParameters['Octopus.Release.Number']\n$gitSource = $null\n$gitDestination = $null\n\n# Clone repository\n$folderName = Invoke-Git -GitRepositoryUrl $gitUrl -GitUsername $gitUser -GitPassword $gitPassword -GitCommand \"clone\" -GitFolder \"$($PWD)/default\"\n\n# Check for tag\nif (![String]::IsNullOrWhitespace($gitTag))\n{\n\t$gitDestination = $folderName\n    $gitSource = Invoke-Git -GitRepositoryUrl $gitUrl -GitUsername $gitUser -GitPassword $gitPassword -GitCommand \"clone\" -GitFolder \"$($PWD)/tags/$gitTag\" -AdditionalArguments @(\"-b\", \"$gitTag\")\n}\nelse\n{\n\t$gitSource = $folderName\n    $gitDestination = $folderName\n}\n\n# Copy files from source to destination\nCopy-Files -SourcePath \"$($gitSource)$($sourceItems)\" -DestinationPath \"$($gitDestination)$($destinationPath)\"\n\n# Set user\n$gitAuthorName = $OctopusParameters['Octopus.Deployment.CreatedBy.DisplayName']\n$gitAuthorEmail = $OctopusParameters['Octopus.Deployment.CreatedBy.EmailAddress']\n\n# Check to see if user is system\nif ([string]::IsNullOrWhitespace($gitAuthorEmail) -and $gitAuthorName -eq \"System\")\n{\n\t# Initiated by the Octopus server via automated process, put something in for the email address\n    $gitAuthorEmail = \"system@octopus.local\"\n}\n\nInvoke-Git -GitCommand \"config\" -AdditionalArguments @(\"user.name\", $gitAuthorName) -GitFolder \"$($folderName)\"\nInvoke-Git -GitCommand \"config\" -AdditionalArguments @(\"user.email\", $gitAuthorEmail) -GitFolder \"$($folderName)\"\n\n# Commit changes\nInvoke-Git -GitCommand \"add\" -GitFolder \"$folderName\" -AdditionalArguments @(\".\")\nInvoke-Git -GitCommand \"commit\" -GitFolder \"$folderName\" -AdditionalArguments @(\"-m\", \"`\"Commit from #{Octopus.Project.Name} release version #{Octopus.Release.Number}`\"\")\n\n# Push the changes back to git\nInvoke-Git -GitCommand \"push\" -GitFolder \"$folderName\"\n\n"
      }
      environments          = []
      excluded_environments = [data.octopusdeploy_environments.development.environments[0].id]
      channels              = []
      tenant_tags           = []
      features              = []
    }

    properties   = {}
    target_roles = []
  }
}