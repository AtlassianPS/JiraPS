#requires -Modules InvokeBuild

[CmdletBinding()]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingEmptyCatchBlock', '')]
param(
    [String[]]$Tag,
    [String[]]$ExcludeTag = @("Integration"),
    [String]$PSGalleryAPIKey,
    [String]$GithubAccessToken
)

$WarningPreference = "Continue"
if ($PSBoundParameters.ContainsKey('Verbose')) {
    $VerbosePreference = "Continue"
}
if ($PSBoundParameters.ContainsKey('Debug')) {
    $DebugPreference = "Continue"
}

try {
    $script:IsWindows = (-not (Get-Variable -Name IsWindows -ErrorAction Ignore)) -or $IsWindows
    $script:IsLinux = (Get-Variable -Name IsLinux -ErrorAction Ignore) -and $IsLinux
    $script:IsMacOS = (Get-Variable -Name IsMacOS -ErrorAction Ignore) -and $IsMacOS
    $script:IsCoreCLR = $PSVersionTable.ContainsKey('PSEdition') -and $PSVersionTable.PSEdition -eq 'Core'
}
catch { }

Set-StrictMode -Version Latest

Import-Module "$PSScriptRoot/Tools/BuildTools.psm1" -Force -ErrorAction Stop

if ($BuildTask -notin @("SetUp", "InstallDependencies")) {
    Import-Module BuildHelpers -Force -ErrorAction Stop
    Invoke-Init
}

#region SetUp
# Synopsis: Proxy task
task Init { Invoke-Init }

# Synopsis: Create an initial environment for developing on the module
task SetUp InstallDependencies, Build

# Synopsis: Install all module used for the development of this module
task InstallDependencies {
    Install-PSDepend
    Import-Module PSDepend -Force
    $parameterPSDepend = @{
        Path        = "$PSScriptRoot/Tools/build.requirements.psd1"
        Install     = $true
        Import      = $false
        Force       = $true
        ErrorAction = "Stop"
    }
    $null = Invoke-PSDepend @parameterPSDepend
    Import-Module BuildHelpers -Force
}

# Synopsis: Get the next version for the build
task GetNextVersion {
    $manifestVersion = [Version](Get-Metadata -Path $env:BHPSModuleManifest)
    try {
        $env:CurrentOnlineVersion = [Version](Find-Module -Name $env:BHProjectName).Version
        $nextOnlineVersion = Get-NextNugetPackageVersion -Name $env:BHProjectName

        if ( ($manifestVersion.Major -gt $nextOnlineVersion.Major) -or
            ($manifestVersion.Minor -gt $nextOnlineVersion.Minor)
            # -or ($manifestVersion.Build -gt $nextOnlineVersion.Build)
        ) {
            $env:NextBuildVersion = [Version]::New($manifestVersion.Major, $manifestVersion.Minor, 0)
        }
        else {
            $env:NextBuildVersion = $nextOnlineVersion
        }
    }
    catch {
        $env:NextBuildVersion = $manifestVersion
    }
}
#endregion Setup

#region HarmonizeVariables
switch ($true) {
    {$IsWindows} {
        $OS = "Windows"
        if (-not ($IsCoreCLR)) {
            $OSVersion = $PSVersionTable.BuildVersion.ToString()
        }
    }
    {$IsLinux} {
        $OS = "Linux"
    }
    {$IsMacOs} {
        $OS = "OSX"
    }
    {$IsCoreCLR} {
        $OSVersion = $PSVersionTable.OS
    }
}
#endregion HarmonizeVariables

#region DebugInformation
task ShowInfo Init, GetNextVersion, {
    Write-Build Gray
    Write-Build Gray ('Running in:                 {0}' -f $env:BHBuildSystem)
    Write-Build Gray '-------------------------------------------------------'
    Write-Build Gray
    Write-Build Gray ('Project name:               {0}' -f $env:BHProjectName)
    Write-Build Gray ('Project root:               {0}' -f $env:BHProjectPath)
    Write-Build Gray ('Build Path:                 {0}' -f $env:BHBuildOutput)
    Write-Build Gray ('Current (online) Version:   {0}' -f $env:CurrentOnlineVersion)
    Write-Build Gray '-------------------------------------------------------'
    Write-Build Gray
    Write-Build Gray ('Branch:                     {0}' -f $env:BHBranchName)
    Write-Build Gray ('Commit:                     {0}' -f $env:BHCommitMessage)
    Write-Build Gray ('Build #:                    {0}' -f $env:BHBuildNumber)
    Write-Build Gray ('Next Version:               {0}' -f $env:NextBuildVersion)
    Write-Build Gray '-------------------------------------------------------'
    Write-Build Gray
    Write-Build Gray ('PowerShell version:         {0}' -f $PSVersionTable.PSVersion.ToString())
    Write-Build Gray ('OS:                         {0}' -f $OS)
    Write-Build Gray ('OS Version:                 {0}' -f $OSVersion)
    Write-Build Gray
}
#endregion DebugInformation

#region BuildRelease
# Synopsis: Build a shippable release
task Build Init, GenerateExternalHelp, CopyModuleFiles, UpdateManifest, CompileModule, PrepareTests

# Synopsis: Generate ./Release structure
task CopyModuleFiles {
    # Setup
    if (-not (Test-Path "$env:BHBuildOutput/$env:BHProjectName")) {
        $null = New-Item -Path "$env:BHBuildOutput/$env:BHProjectName" -ItemType Directory
    }

    # Copy module
    Copy-Item -Path "$env:BHModulePath/*" -Destination "$env:BHBuildOutput/$env:BHProjectName" -Recurse -Force
    # Copy additional files
    Copy-Item -Path @(
        "$env:BHProjectPath/CHANGELOG.md"
        "$env:BHProjectPath/LICENSE"
        "$env:BHProjectPath/README.md"
    ) -Destination "$env:BHBuildOutput/$env:BHProjectName" -Force
}

# Synopsis: Prepare tests for ./Release
task PrepareTests Init, {
    $null = New-Item -Path "$env:BHBuildOutput/Tests" -ItemType Directory -ErrorAction SilentlyContinue
    Copy-Item -Path "$env:BHProjectPath/Tests" -Destination $env:BHBuildOutput -Recurse -Force
    Copy-Item -Path "$env:BHProjectPath/PSScriptAnalyzerSettings.psd1" -Destination $env:BHBuildOutput -Force
}

# Synopsis: Compile all functions into the .psm1 file
task CompileModule Init, {
    $regionsToKeep = @('Dependencies', 'Configuration')

    $targetFile = "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psm1"
    $content = Get-Content -Encoding UTF8 -LiteralPath $targetFile
    $capture = $false
    $compiled = ""

    foreach ($line in $content) {
        if ($line -match "^#region ($($regionsToKeep -join "|"))$") {
            $capture = $true
        }
        if (($capture -eq $true) -and ($line -match "^#endregion")) {
            $capture = $false
        }

        if ($capture) {
            $compiled += "$line`r`n"
        }
    }

    $PublicFunctions = @( Get-ChildItem -Path "$env:BHBuildOutput/$env:BHProjectName/Public/*.ps1" -ErrorAction SilentlyContinue )
    $PrivateFunctions = @( Get-ChildItem -Path "$env:BHBuildOutput/$env:BHProjectName/Private/*.ps1" -ErrorAction SilentlyContinue )

    foreach ($function in @($PublicFunctions + $PrivateFunctions)) {
        $compiled += (Get-Content -Path $function.FullName -Raw)
        $compiled += "`r`n"
    }

    Set-Content -LiteralPath $targetFile -Value $compiled -Encoding UTF8 -Force
    Remove-Utf8Bom -Path $targetFile

    "Private", "Public" | Foreach-Object { Remove-Item -Path "$env:BHBuildOutput/$env:BHProjectName/$_" -Recurse -Force }
}

# Synopsis: Use PlatyPS to generate External-Help
task GenerateExternalHelp Init, {
    Import-Module platyPS -Force
    foreach ($locale in (Get-ChildItem "$env:BHProjectPath/docs" -Attribute Directory)) {
        New-ExternalHelp -Path "$($locale.FullName)" -OutputPath "$env:BHModulePath/$($locale.Basename)" -Force
        New-ExternalHelp -Path "$($locale.FullName)/commands" -OutputPath "$env:BHModulePath/$($locale.Basename)" -Force
    }
    Remove-Module platyPS
}

# Synopsis: Update the manifest of the module
task UpdateManifest GetNextVersion, {
    Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
    Import-Module $env:BHPSModuleManifest -Force
    $ModuleAlias = @(Get-Alias | Where-Object {$_.ModuleName -eq "$env:BHProjectName"})

    BuildHelpers\Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -PropertyName ModuleVersion -Value $env:NextBuildVersion
    # BuildHelpers\Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -PropertyName FileList -Value (Get-ChildItem "$env:BHBuildOutput/$env:BHProjectName" -Recurse).Name
    BuildHelpers\Set-ModuleFunctions -Name "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -FunctionsToExport ([string[]](Get-ChildItem "$env:BHBuildOutput/$env:BHProjectName/Public/*.ps1").BaseName)
    BuildHelpers\Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -PropertyName AliasesToExport -Value ''
    if ($ModuleAlias) {
        BuildHelpers\Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -PropertyName AliasesToExport -Value @($ModuleAlias.Name)
    }
}

# Synopsis: Create a ZIP file with this build
task Package Init, {
    Assert-True { Test-Path "$env:BHBuildOutput\$env:BHProjectName" } "Missing files to package"

    Remove-Item "$env:BHBuildOutput\$env:BHProjectName.zip" -ErrorAction SilentlyContinue
    $null = Compress-Archive -Path "$env:BHBuildOutput\$env:BHProjectName" -DestinationPath "$env:BHBuildOutput\$env:BHProjectName.zip"
}
#endregion BuildRelease

#region Test
task Test Init, {
    Assert-True { Test-Path $env:BHBuildOutput -PathType Container } "Release path must exist"

    Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue

    <# $params = @{
        Path    = "$env:BHBuildOutput/$env:BHProjectName"
        Include = '*.ps1', '*.psm1'
        Recurse = $True
        Exclude = $CodeCoverageExclude
    }
    $codeCoverageFiles = Get-ChildItem @params #>

    try {
        $parameter = @{
            Script       = "$env:BHBuildOutput/Tests/*"
            Tag          = $Tag
            ExcludeTag   = $ExcludeTag
            Show         = "Fails"
            PassThru     = $true
            OutputFile   = "$env:BHProjectPath/Test-$OS-$($PSVersionTable.PSVersion.ToString()).xml"
            OutputFormat = "NUnitXml"
            # CodeCoverage = $codeCoverageFiles
        }
        $testResults = Invoke-Pester @parameter

        Assert-True ($testResults.FailedCount -eq 0) "$($testResults.FailedCount) Pester test(s) failed."
    }
    catch {
        throw $_
    }
}, { Init }
#endregion

#region Publish
# Synopsis: Publish a new release on github and the PSGallery
task Deploy Init, PublishToGallery, TagReplository, UpdateHomepage

# Synpsis: Publish the $release to the PSGallery
task PublishToGallery {
    Assert-True (-not [String]::IsNullOrEmpty($PSGalleryAPIKey)) "No key for the PSGallery"
    Assert-True {Get-Module $env:BHProjectName -ListAvailable} "Module $env:BHProjectName is not available"

    Remove-Module $env:BHProjectName -ErrorAction Ignore

    Publish-Module -Name $env:BHProjectName -NuGetApiKey $PSGalleryAPIKey
}

# Synopsis: push a tag with the version to the git repository
task TagReplository GetNextVersion, Package, {
    Assert-True (-not [String]::IsNullOrEmpty($GithubAccessToken)) "No key for the PSGallery"

    $releaseText = "Release version $env:NextBuildVersion"

    # Push a tag to the repository
    Write-Build Gray "git checkout $ENV:BHBranchName"
    cmd /c "git checkout $ENV:BHBranchName 2>&1"

    Write-Build Gray "git tag -a v$env:NextBuildVersion"
    cmd /c "git tag -a v$env:NextBuildVersion 2>&1 -m `"$releaseText`""

    Write-Build Gray "git push origin v$env:NextBuildVersion"
    cmd /c "git push origin v$env:NextBuildVersion 2>&1"

    # Publish a release on github for the tag above
    $releaseResponse = Publish-GithubRelease -GITHUB_ACCESS_TOKEN $GithubAccessToken -ReleaseText $releaseText -NextBuildVersion $env:NextBuildVersion

    # Upload the package of the version to the release
    $packageFile = Get-Item "$env:BHBuildOutput\$env:BHProjectName.zip" -ErrorAction Stop
    $uploadURI = $releaseResponse.upload_url -replace "\{\?name,label\}", "?name=$($packageFile.Name)"
    $null = Publish-GithubReleaseArtifact -GITHUB_ACCESS_TOKEN $GithubAccessToken -Uri $uploadURI -Path $packageFile
}

# Synopsis: Update the version of this module that the homepage uses
task UpdateHomepage {
    try {
        Add-Content (Join-Path $Home ".git-credentials") "https://$GithubAccessToken:x-oauth-basic@github.com`n"

        Write-Build Gray "git config --global credential.helper `"store --file ~/.git-credentials`""
        git config --global credential.helper "store --file ~/.git-credentials"

        Write-Build Gray "git config --global user.email `"support@atlassianps.org`""
        git config --global user.email "support@atlassianps.org"

        Write-Build Gray "git config --global user.name `"AtlassianPS automation`""
        git config --global user.name "AtlassianPS automation"

        Write-Build Gray "git close .../AtlassianPS.github.io --recursive"
        $null = cmd /c "git clone https://github.com/AtlassianPS/AtlassianPS.github.io --recursive 2>&1"

        Push-Location "AtlassianPS.github.io/"

        Write-Build Gray "git submodule foreach git pull origin master"
        $null = cmd /c "git submodule foreach git pull origin master 2>&1"

        Write-Build Gray "git status -s"
        $status = cmd /c "git status -s 2>&1"

        if ($status -contains " M modules/$env:BHProjectName") {
            Write-Build Gray "git add modules/$env:BHProjectName"
            $null = cmd /c "git add modules/$env:BHProjectName 2>&1"

            Write-Build Gray "git commit -m `"Update module $env:BHProjectName`""
            cmd /c "git commit -m `"Update module $env:BHProjectName`" 2>&1"

            Write-Build Gray "git push"
            cmd /c "git push 2>&1"
        }

        Pop-Location
    }
    catch { Write-Warning "Failed to deploy to homepage"}
}
#endregion Publish

#region Cleaning tasks
# Synopsis: Clean the working dir
task Clean Init, RemoveGeneratedFiles, RemoveTestResults

# Synopsis: Remove generated and temp files.
task RemoveGeneratedFiles {
    Remove-Item "$env:BHModulePath/en-US/*" -Force -ErrorAction SilentlyContinue
    Remove-Item $env:BHBuildOutput -Force -Recurse -ErrorAction SilentlyContinue
}

# Synopsis: Remove Pester results
task RemoveTestResults {
    Remove-Item "Test-*.xml" -Force -ErrorAction SilentlyContinue
}
#endregion

task . ShowInfo, Clean, Build, Test

Remove-Item -Path Env:\BH*
