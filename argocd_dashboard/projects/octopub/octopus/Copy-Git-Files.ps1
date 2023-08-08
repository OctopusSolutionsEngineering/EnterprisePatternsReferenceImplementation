Function Invoke-Git
{
	# Define parameters
    param (
    	$GitRepositoryUrl,
        $GitFolder,
        $GitUsername,
        $GitPassword,
        $GitCommand,
        $AdditionalArguments
    )

    # Get current work folder
    $workDirectory = Get-Location

	# Check to see if GitFolder exists
    if (![String]::IsNullOrWhitespace($GitFolder) -and (Test-Path -Path $GitFolder) -eq $false)
    {
    	# Create the folder
        New-Item -Path $GitFolder -ItemType "Directory" -Force | Out-Null

        # Set the location to the new folder
        Set-Location -Path $GitFolder
    }

    # Create arguments array
    $gitArguments = @()
    $gitArguments += $GitCommand

    # Check for url
    if (![string]::IsNullOrWhitespace($GitRepositoryUrl))
    {
      # Convert url to URI object
      $gitUri = [System.Uri]$GitRepositoryUrl
      $gitUrl = "{0}://{1}:{2}@{3}:{4}{5}" -f $gitUri.Scheme, $GitUsername, $GitPassword, $gitUri.Host, $gitUri.Port, $gitUri.PathAndQuery
      $gitArguments += $gitUrl

      # Get the newly created folder name
      $gitFolderName = $GitRepositoryUrl.SubString($GitRepositoryUrl.LastIndexOf("/") + 1)
      if ($gitFolderName.Contains(".git"))
      {
          $gitFolderName = $gitFolderName.SubString(0, $gitFolderName.IndexOf("."))
      }
    }


    # Check for additional arguments
    if ($null -ne $AdditionalArguments)
    {
 		# Add the additional arguments
        $gitArguments += $AdditionalArguments
    }

    # Execute git command
    $results = Execute-Command -commandPath "git" -commandArguments $gitArguments -workingDir $GitFolder

    Write-Host $results.stdout
    Write-Host $results.stderr

    # Return the foldername
    Set-Location -Path $workDirectory
   	return Join-Path -Path $GitFolder -ChildPath $gitFolderName
}

# Check to see if $IsWindows is available
if ($null -eq $IsWindows) {
    Write-Host "Determining Operating System..."
    $IsWindows = ([System.Environment]::OSVersion.Platform -eq "Win32NT")
    $IsLinux = ([System.Environment]::OSVersion.Platform -eq "Unix")
}

Function Copy-Files
{
	# Define parameters
    param (
    	$SourcePath,
        $DestinationPath
    )

    # Copy the items from source path to destination path
    $copyArguments = @{}
    $copyArguments.Add("Path", $SourcePath)
    $copyArguments.Add("Destination", $DestinationPath)

    # Check to make sure destination exists
    if ((Test-Path -Path $DestinationPath) -eq $false)
    {
    	# Create the destination path
        New-Item -Path $DestinationPath -ItemType "Directory" | Out-Null
    }

    # Check for wildcard
    if ($SourcePath.EndsWith("/*") -or $SourcePath.EndsWith("\*"))
    {
		# Add recurse argument
		$copyArguments.Add("Recurse", $true)
    }

    # Copy files
    Copy-Item @copyArguments
}

Function Execute-Command
{
	param (
    	$commandPath,
        $commandArguments,
        $workingDir
    )

	$gitExitCode = 0
    $executionResults = $null

  Try {
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $commandPath
    $pinfo.WorkingDirectory = $workingDir
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $commandArguments
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $executionResults = [pscustomobject]@{
        stdout = $p.StandardOutput.ReadToEnd()
        stderr = $p.StandardError.ReadToEnd()
        ExitCode = $p.ExitCode
    }
    $p.WaitForExit()
    $gitExitCode = [int]$p.ExitCode

    if ($gitExitCode -ge 2)
    {
		# Fail the step
        throw
    }

    return $executionResults
  }
  Catch {
    # Check exit code
    Write-Error -Message "$($executionResults.stderr)" -ErrorId $gitExitCode
    exit $gitExitCode
  }

}


# Get variables
$gitUrl = $OctopusParameters['Project.Git.Url']
$gitUser = $OctopusParameters['Project.Git.Username']
$gitPassword = $OctopusParameters['Project.Git.Password']
$sourceItems = $OctopusParameters['Project.Git.SourceItems']
$destinationPath = $OctopusParameters['Project.Git.DestinationPath']
$gitTag = $OctopusParameters['Octopus.Release.Number']
$gitSource = $null
$gitDestination = $null

# Clone repository
$folderName = Invoke-Git -GitRepositoryUrl $gitUrl -GitUsername $gitUser -GitPassword $gitPassword -GitCommand "clone" -GitFolder "$($PWD)/default"

# Check for tag
if (![String]::IsNullOrWhitespace($gitTag))
{
	$gitDestination = $folderName
    $gitSource = Invoke-Git -GitRepositoryUrl $gitUrl -GitUsername $gitUser -GitPassword $gitPassword -GitCommand "clone" -GitFolder "$($PWD)/tags/$gitTag" -AdditionalArguments @("-b", "$gitTag")
}
else
{
	$gitSource = $folderName
    $gitDestination = $folderName
}

# Copy files from source to destination
Copy-Files -SourcePath "$($gitSource)$($sourceItems)" -DestinationPath "$($gitDestination)$($destinationPath)"

# Set user
$gitAuthorName = $OctopusParameters['Octopus.Deployment.CreatedBy.DisplayName']
$gitAuthorEmail = $OctopusParameters['Octopus.Deployment.CreatedBy.EmailAddress']

# Check to see if user is system
if ([string]::IsNullOrWhitespace($gitAuthorEmail) -and $gitAuthorName -eq "System")
{
	# Initiated by the Octopus server via automated process, put something in for the email address
    $gitAuthorEmail = "system@octopus.local"
}

Invoke-Git -GitCommand "config" -AdditionalArguments @("user.name", $gitAuthorName) -GitFolder "$($folderName)"
Invoke-Git -GitCommand "config" -AdditionalArguments @("user.email", $gitAuthorEmail) -GitFolder "$($folderName)"

# Commit changes
Invoke-Git -GitCommand "add" -GitFolder "$folderName" -AdditionalArguments @(".")
Invoke-Git -GitCommand "commit" -GitFolder "$folderName" -AdditionalArguments @("-m", "`"Commit from #{Octopus.Project.Name} release version #{Octopus.Release.Number}`"")

# Push the changes back to git
Invoke-Git -GitCommand "push" -GitFolder "$folderName"

