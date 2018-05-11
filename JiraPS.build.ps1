[CmdletBinding()]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingEmptyCatchBlock', '')]
param(
    [String[]]$Tag,
    [String[]]$ExcludeTag
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

Import-Module "$PSScriptRoot/Tools/build.psm1" -Force -ErrorAction Stop
if ($BuildTask -ne "InstallDependencies") {
    Import-Module BuildHelpers -Force -ErrorAction Stop
}

#region SetUp
# Synopsis: Create an initial environment for developing on the module
task SetUp InstallDependencies, Build

# Synopsis: Install all module used for the development of this module
task InstallDependencies {
    Install-PSDepend
    Import-Module PSDepend -Force
    $parameterPSDepend = @{
        Path        = "$PSScriptRoot/Tools/build.requirements.psd1"
        Install     = $true
        Import      = $true
        Force       = $true
        ErrorAction = "Stop"
    }
    $null = Invoke-PSDepend @parameterPSDepend
    Import-Module BuildHelpers -Force
}

# Synopsis: Ensure the build environment is all ready to go
task Init {
    Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -ErrorAction SilentlyContinue
}, GetNextVersion

# Synopsis: Get the next version for the build
task GetNextVersion {
    $currentVersion = [Version](Get-Metadata -Path $env:BHPSModuleManifest)
    if ($env:BHBuildNumber) {
        $newRevision = $env:BHBuildNumber
    }
    else {
        $newRevision = 0
    }
    $env:NextBuildVersion = [Version]::New($currentVersion.Major, $currentVersion.Minor, $newRevision)
    $env:CurrentBuildVersion = $currentVersion
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
task ShowInfo Init, {
    Write-Build Gray
    Write-Build Gray ('Running in:                 {0}' -f $env:BHBuildSystem)
    Write-Build Gray '-------------------------------------------------------'
    Write-Build Gray
    Write-Build Gray ('Project name:               {0}' -f $env:BHProjectName)
    Write-Build Gray ('Project root:               {0}' -f $env:BHProjectPath)
    Write-Build Gray ('Build Path:                 {0}' -f $env:BHBuildOutput)
    Write-Build Gray ('Current Version:            {0}' -f $env:CurrentBuildVersion)
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
task Build GenerateRelease, UpdateManifest

# Synopsis: Generate ./Release structure
task GenerateRelease Init, GenerateExternalHelp, {
    # Setup
    if (-not (Test-Path "$env:BHBuildOutput/$env:BHProjectName")) {
        $null = New-Item -Path "$env:BHBuildOutput/$env:BHProjectName" -ItemType Directory
    }

    # Copy module
    Copy-Item -Path "$env:BHModulePath/*" -Destination "$env:BHBuildOutput/$env:BHProjectName" -Recurse -Force
    # Copy additional files
    Copy-Item -Path @(
        "$BuildRoot/CHANGELOG.md"
        "$BuildRoot/LICENSE"
        "$BuildRoot/README.md"
    ) -Destination "$env:BHBuildOutput/$env:BHProjectName" -Force
    # Copy Tests
    $null = New-Item -Path "$env:BHBuildOutput/Tests" -ItemType Directory -ErrorAction SilentlyContinue
    Copy-Item -Path "$BuildRoot/Tests/*.ps1" -Destination "$env:BHBuildOutput/Tests" -Recurse -Force
    # Include Analyzer Settings
    Copy-Item -Path "$BuildRoot/PSScriptAnalyzerSettings.psd1" -Destination "$env:BHBuildOutput/PSScriptAnalyzerSettings.psd1" -Force
    # Remove all execptions from PSScriptAnalyzer
    BuildHelpers\Update-Metadata -Path "$env:BHBuildOutput/PSScriptAnalyzerSettings.psd1" -PropertyName ExcludeRules -Value ''
}

# Synopsis: Use PlatyPS to generate External-Help
task GenerateExternalHelp -If (Get-ChildItem "$BuildRoot/docs/en-US/commands" -ErrorAction SilentlyContinue) Init, {
    Import-Module platyPS -Force
    foreach ($locale in (Get-ChildItem "$BuildRoot/docs" -Attribute Directory)) {
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

    Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
    Import-Module "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -Force

    BuildHelpers\Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -PropertyName ModuleVersion -Value $env:NextBuildVersion
    # BuildHelpers\Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -PropertyName FileList -Value (Get-ChildItem "$env:BHBuildOutput/$env:BHProjectName" -Recurse).Name
    BuildHelpers\Set-ModuleFunctions -Name "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -FunctionsToExport ([string[]](Get-ChildItem "$env:BHBuildOutput/$env:BHProjectName/Public/*.ps1").BaseName)
    BuildHelpers\Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -PropertyName AliasesToExport -Value ''
    if ($ModuleAlias) {
        BuildHelpers\Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -PropertyName AliasesToExport -Value @($ModuleAlias.Name)
    }
}
#endregion BuildRelease

#region Test
task Test Init, {
    assert { Test-Path $env:BHBuildOutput -PathType Container }

    Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue

    $params = @{
        Path    = "$env:BHBuildOutput/$env:BHProjectName"
        Include = '*.ps1', '*.psm1'
        Recurse = $True
        # Exclude = $CodeCoverageExclude
    }
    $codeCoverageFiles = Get-ChildItem @params

    try {
        $parameter = @{
            Script       = "$env:BHBuildOutput/Tests/*"
            Tag          = $Tag
            ExcludeTag   = $ExcludeTag
            PassThru     = $true
            OutputFile   = "$BuildRoot/TestResult.xml"
            OutputFormat = "NUnitXml"
            CodeCoverage = $codeCoverageFiles
        }
        $testResults = Invoke-Pester @parameter

        If ('AppVeyor' -eq $env:BHBuildSystem) {
            BuildHelpers\Add-TestResultToAppveyor -TestFile $parameter["OutputFile"]
        }

        assert ($testResults.FailedCount -eq 0) "$($testResults.FailedCount) Pester test(s) failed."
    }
    catch {
        throw $_
    }
}, RemoveTestResults, RemoveConfig
#endregion

#region Publish

$shouldDeploy = (
    # only deploy master branch
    ('master' -eq $env:BHBranchName) -and
    # only deploy from AppVeyor
    ('AppVeyor' -eq $env:BHBuildSystem) -and
    # it cannot be a PR
    (-not ($env:APPVEYOR_PULL_REQUEST_NUMBER)) -and
    # only deploy from last Job
    (allJobsFinished) -and
    # it cannot have a commit message that contains "skip-deploy"
    ($env:BHCommitMessage -notlike '*skip-deploy*')
)
# Synopsis: Publish a new release on github and the PSGallery
task Deploy -If { $shouldDeploy } Init, PublishToGallery, TagReplository

# Synipsis: Publish the $release to the PSGallery
task PublishToGallery {
    assert ($env:PSGalleryAPIKey) "No key for the PSGallery"

    Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
    Import-Module "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -ErrorAction Stop
    Publish-Module -Name $env:BHProjectName -NuGetApiKey $env:PSGalleryAPIKey
}

task TagReplository GetNextVersion, {
    Write-Build Gray "git checkout $ENV:BHBranchName"
    cmd /c "git checkout $ENV:BHBranchName 2>&1"
    Write-Build Gray "git tag -a v$env:NextBuildVersion"
    cmd /c "git tag -a v$env:NextBuildVersion 2>&1"
    Write-Build Gray "git push origin v$env:NextBuildVersion"
    cmd /c "git push origin v$env:NextBuildVersion 2>&1"
    # $parameters = @{
    #     Path        = $ReleaseNotes
    #     ErrorAction = 'SilentlyContinue'
    # }
    # $releaseText = (Get-Content @parameters) -join "`r`n"
    # if (-not $ReleaseText) {
    $releaseText = "Release version $env:NextBuildVersion"
    # }
    $body = @{
        "tag_name"         = "v$env:NextBuildVersion"
        "target_commitish" = "master"
        "name"             = "v$env:NextBuildVersion"
        "body"             = $releaseText
        "draft"            = $false
        "prerelease"       = $false
    } | ConvertTo-Json
    $releaseParams = @{
        Uri         = "https://api.github.com/repos/{0}/releases" -f $env:BHProjectName
        Method      = 'POST'
        Headers     = @{
            Authorization = 'Basic ' + [Convert]::ToBase64String(
                [Text.Encoding]::ASCII.GetBytes($env:access_token + ":x-oauth-basic")
            )
        }
        ContentType = 'application/json'
        Body        = $body
        ErrorAction = "Stop"
    }
    $response = Invoke-RestMethod @releaseParams
    $response | Format-List *
}
#endregion Publish

#region Cleaning tasks
# Synopsis: Clean the working dir
task Clean RemoveGeneratedFiles, RemoveTestResults, RemoveConfig

# Synopsis: Remove generated and temp files.
task RemoveGeneratedFiles {
    Remove-Item $env:BHBuildOutput -Force -Recurse -ErrorAction SilentlyContinue
}

# Synopsis: Remove Pester results
task RemoveTestResults {
    Remove-Item "TestResult.xml" -Force -ErrorAction SilentlyContinue
}

# Synopsis: Remove Jira config file
task RemoveConfig {
    Remove-Item "$env:BHBuildOutput\config.xml" -Force -ErrorAction SilentlyContinue
}
#endregion

task . ShowInfo, Clean, Build, Test, Deploy

Remove-Item -Path Env:\BH*
