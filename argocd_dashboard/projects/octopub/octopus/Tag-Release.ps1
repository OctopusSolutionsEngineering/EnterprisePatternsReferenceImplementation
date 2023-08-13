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
    $results = Execute-Command "git" $gitArguments $GitFolder

    Write-Host $results.stdout
    Write-Host $results.stderr

    # Return the foldername
   	return $gitFolderName
}

# Check to see if $IsWindows is available
if ($null -eq $IsWindows) {
    Write-Host "Determining Operating System..."
    $IsWindows = ([System.Environment]::OSVersion.Platform -eq "Win32NT")
    $IsLinux = ([System.Environment]::OSVersion.Platform -eq "Unix")
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
$gitUrl = $OctopusParameters['Template.Git.Repo.Url']
$gitUser = $OctopusParameters['Template.Git.User.Name']
$gitPassword = $OctopusParameters['Template.Git.User.Password']
$gitTag = $OctopusParameters['Template.Git.Tag']

# Clone repository
$folderName = Invoke-Git -GitRepositoryUrl $gitUrl -GitUsername $gitUser -GitPassword $gitPassword -GitCommand "clone"

# Set user
$gitAuthorName = $OctopusParameters['Octopus.Deployment.CreatedBy.DisplayName']
$gitAuthorEmail = $OctopusParameters['Octopus.Deployment.CreatedBy.EmailAddress']

# Check to see if user is system
if ([string]::IsNullOrWhitespace($gitAuthorEmail) -and $gitAuthorName -eq "System")
{
	# Initiated by the Octopus server via automated process, put something in for the email address
    $gitAuthorEmail = "system@octopus.local"
}

# Configure user information
Invoke-Git -GitCommand "config" -AdditionalArguments @("user.name", $gitAuthorName) -GitFolder "$($PWD)/$($folderName)"
Invoke-Git -GitCommand "config" -AdditionalArguments @("user.email", $gitAuthorEmail) -GitFolder "$($PWD)/$($folderName)"

# Tag the repo
Invoke-Git -GitCommand "tag" -AdditionalArguments @("-a", $gitTag, "-m", "`"Tag from #{Octopus.Project.Name} release version #{Octopus.Release.Number}`"") -GitFolder "$($PWD)/$($folderName)"

# Push the new tag
Invoke-Git -Gitcommand "push" -AdditionalArguments @("--tags") -GitFolder "$($PWD)/$($folderName)"