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

    # Check to see if GitFolder is null
    if ($null -ne $GitFolder)
    {
        return Join-Path -Path $GitFolder -ChildPath $gitFolderName
    }
}

Function Get-GitExecutable
{
    # Define parameters
    param (
        $WorkingDirectory
    )

    # Define variables
    $gitExe = "PortableGit-2.41.0.3-64-bit.7z.exe"
    $gitDownloadUrl = "https://github.com/git-for-windows/git/releases/download/v2.41.0.windows.3/$gitExe"
    $gitDownloadArguments = @{}
    $gitDownloadArguments.Add("Uri", $gitDownloadUrl)
    $gitDownloadArguments.Add("OutFile", "$WorkingDirectory/git/$gitExe")

    # This makes downloading faster
    $ProgressPreference = 'SilentlyContinue'

    # Check to see if git subfolder exists
    if ((Test-Path -Path "$WorkingDirectory/git") -eq $false)
    {
        # Create subfolder
        New-Item -Path "$WorkingDirectory/git"  -ItemType Directory
    }

    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 6)
    {
        # Use basic parsing is required
        $gitDownloadArguments.Add("UseBasicParsing", $true)
    }

    # Download Git
    Write-Host "Downloading Git ..."
    Invoke-WebRequest @gitDownloadArguments

    # Extract Git
    $gitExtractArguments = @()
    $gitExtractArguments += "-o"
    $gitExtractArguments += "$WorkingDirectory\git"
    $gitExtractArguments += "-y"
    $gitExtractArguments += "-bd"

    Write-Host "Extracting Git download ..."
    & "$WorkingDirectory\git\$gitExe" $gitExtractArguments

    # Wait until unzip action is complete
    while ($null -ne (Get-Process | Where-Object {$_.ProcessName -eq ($gitExe.Substring(0, $gitExe.LastIndexOf(".")))}))
    {
        Start-Sleep 5
    }

    # Add bin folder to path
    $env:PATH = "$WorkingDirectory\git\bin$([IO.Path]::PathSeparator)" + $env:PATH

    # Disable promopt for credential helper
    Invoke-Git -GitCommand "config" -AdditionalArguments @("--system", "--unset", "credential.helper")
}

Function Get-LatestVersionDownloadUrl {
    # Define parameters
    param(
        $Repository,
        $Version
    )

    # Define local variables
    $releases = "https://api.github.com/repos/$Repository/releases"

    # Get latest version
    Write-Host "Determining latest release of $Repository ..."

    $tags = (Invoke-WebRequest $releases -UseBasicParsing | ConvertFrom-Json)

    if ($null -ne $Version) {
        # Get specific version
        $tags = ($tags | Where-Object { $_.name.EndsWith($Version) })

        # Check to see if nothing was returned
        if ($null -eq $tags) {
            # Not found
            Write-Host "No release found matching version $Version, getting highest version using Major.Minor syntax..."

            # Get the tags
            $tags = (Invoke-WebRequest $releases -UseBasicParsing | ConvertFrom-Json)

            # Parse the version number into a version object
            $parsedVersion = [System.Version]::Parse($Version)
            $partialVersion = "$($parsedVersion.Major).$($parsedVersion.Minor)"

            # Filter tags to ones matching only Major.Minor of version specified
            $tags = ($tags | Where-Object { $_.name.Contains("$partialVersion.") -and $_.draft -eq $false })

            # Grab the latest
            $tags = $tags[0]
        }
    }

    # Find the latest version with a downloadable asset
    foreach ($tag in $tags) {
        if ($tag.assets.Count -gt 0) {
            return $tag.assets.browser_download_url
        }
    }

    # Return the version
    return $null
}

Function Get-Tool
{
    # Define parameters
    param (
        $ToolUrl
    )

    # Download GitHub CLI
    $downloadArguments = @{}
    $downloadArguments.Add("OutFile", "$PWD/tools/$($ToolUrl.Substring($ToolUrl.LastIndexOf("/") + 1))")
    $downloadArguments.Add("Uri", $ToolUrl)

    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 6)
    {
        # Use basic parsing is required
        $downloadArguments.Add("UseBasicParsing", $true)
    }

    Invoke-WebRequest @downloadArguments
}

# Check to see if $IsWindows is available
if ($null -eq $IsWindows) {
    Write-Host "Determining Operating System..."
    $IsWindows = ([System.Environment]::OSVersion.Platform -eq "Win32NT")
    $IsLinux = ([System.Environment]::OSVersion.Platform -eq "Unix")
}

# Fix ANSI Color on PWSH Core issues when displaying objects
if ($PSEdition -eq "Core") {
    $PSStyle.OutputRendering = "PlainText"
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
$gitSourceBranch = $OctopusParameters['Template.Git.Source.Branch']
$gitDestinationBranch = $OctopusParameters['Template.Git.Destination.Branch']
$gitTech = $OctopusParameters['Template.Git.Repository.Technology']

# Create tools folder
New-Item -Path "$PWD/tools" -ItemType "Directory" -Force | Out-Null

# Check to see if it's Windows
if ($IsWindows -and $OctopusParameters['Octopus.Workerpool.Name'] -eq "Hosted Windows")
{
    # Dynamic worker don't have git, download portable version and add to path for execution
    Write-Host "Detected usage of Windows Dynamic Worker ..."
    Get-GitExecutable -WorkingDirectory $PWD
}

# Clone repository
#$folderName = Invoke-Git -GitRepositoryUrl $gitUrl -GitUsername $gitUser -GitPassword $gitPassword -GitCommand "clone" -AdditionalArguments @("-b", $gitSourceBranch)

switch ($gitTech)
{
    "ado"
    {

    }
    "bitbucket"
    {

    }
    "github"
    {
        # Get github cli
        $downloadUrls = Get-LatestVersionDownloadUrl -Repository "cli/cli"

        # Check which OS we're using
        if ($IsWindows)
        {
            # Filter download urls to the windows zip one
            $downloadUrl = $downloadUrls | Where-Object {$_.Contains("windows") -and $_.Contains("amd64") -and $_.EndsWith(".zip")}

            # Get the Windows version
            Get-Tool -ToolUrl $downloadUrl

            # Expand the archive
            Expand-Archive -Path "$PWD/tools/$($downloadUrl.Substring($downloadUrl.LastIndexOf("/") + 1))" -DestinationPath "$PWD/tools/"
        }

        if ($IsLinux)
        {
            # Filter download urls to the windows zip one
            $downloadUrl = $downloadUrls | Where-Object {$_.Contains("linux") -and $_.Contains("amd64") -and $_.EndsWith(".tar.gz")}

            # Get the Linux version
            Get-Tool -ToolUrl $downloadUrl

            # Expand the archive
            tar -xvzf "$PWD/tools/$($downloadUrl.Substring($downloadUrl.LastIndexOf("/") + 1))" --directory "$PWD/tools/" | Out-Null
        }

        # Add tools to path
        $env:PATH = "$PWD/tools/bin$([IO.Path]::PathSeparator)" + $env:PATH

        # Set environment variable used for authentication -- works only with GH tokens, password will not work
        $env:GH_TOKEN = $gitPassword

        Write-Host "Pre-clone"

        # Clone the source branch
        $folderName = Invoke-Git -GitCommand "clone" -AdditionalArguments @("--branch", $gitSourceBranch) -GitRepositoryUrl $gitUrl -GitFolder $PWD

        Write-Host "it is $folderName"

        # Switch to foldername
        Set-Location -Path $folderName

        # Create pull request from branch
        $ghArguments = @()
        $ghArguments += "pr"
        $ghArguments += "create"
        $ghArguments += "--base"
        $ghArguments += $gitDestinationBranch
        $ghArguments += "--head"
        $ghArguments += $gitSourceBranch
        $ghArguments += "--fill"

        #gh pr create --base $gitDestonationBranch --head $gitSourceBranch --fill
        gh $ghArguments
    }
    "gitlab"
    {

    }
}

<#
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
Invoke-Git -GitCommand "config" -AdditionalArguments @("user.name", $gitAuthorName) #-GitFolder "$($PWD)/$($folderName)"
Invoke-Git -GitCommand "config" -AdditionalArguments @("user.email", $gitAuthorEmail) #-GitFolder "$($PWD)/$($folderName)"


# Push the new tag
Invoke-Git -Gitcommand "request-pull" -AdditionalArguments @("$gitSourceBranch", $gitUrl, "$gitDestinationBranch") -GitFolder "$($PWD)/$($folderName)"
#>