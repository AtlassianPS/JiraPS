[CmdletBinding()]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingEmptyCatchBlock', '')]
param(
    [String[]]$Tag,
    [String[]]$ExcludeTag
)

#region Setup
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

function Get-AppVeyorBuild {
    param()

    if (-not ($env:APPVEYOR_API_TOKEN)) {
        throw "missing api token for AppVeyor."
    }
    if (-not ($env:APPVEYOR_ACCOUNT_NAME)) {
        throw "not an appveyor build."
    }

    Invoke-RestMethod -Uri "https://ci.appveyor.com/api/projects/$env:APPVEYOR_ACCOUNT_NAME/$env:APPVEYOR_PROJECT_SLUG" -Method GET -Headers @{
        "Authorization" = "Bearer $env:APPVEYOR_API_TOKEN"
        "Content-type"  = "application/json"
    }
}
function Get-TravisBuild {
    param()

    if (-not ($env:TRAVIS_API_TOKEN)) {
        throw "missing api token for Travis-CI."
    }
    if (-not ($env:APPVEYOR_ACCOUNT_NAME)) {
        throw "not an appveyor build."
    }

    Invoke-RestMethod -Uri "https://api.travis-ci.org/builds?limit=10" -Method Get -Headers @{
        "Authorization"      = "token $env:TRAVIS_API_TOKEN"
        "Travis-API-Version" = "3"
    }
}

Set-StrictMode -Version Latest

# Synopsis: Create an initial environment for developing on the module
task SetUp InstallDependencies, Build

# Synopsis: Install all module used for the development of this module
task InstallDependencies InstallPandoc, {
    # Set default parameters for `Install-Module`
    $PSDefaultParameterValues["install-Module:Scope"] = "CurrentUser"
    $PSDefaultParameterValues["install-Module:Force"] = $true

    $AllowClobber = @{}
    $SkipPublisherCheck = @{}
    # PSv4 does not have the parameter `-SkipPublisherCheck` and `-AllowClobber`
    if ((Get-Command Install-Module).Parameters.Keys -contains "AllowClobber") {
        $AllowClobber["AllowClobber"] = $true
    }
    if ((Get-Command Install-Module).Parameters.Keys -contains "SkipPublisherCheck") {
        $SkipPublisherCheck["SkipPublisherCheck"] = $true
    }

    Write-Host "Installing Configuration"
    Install-Module "Configuration" -RequiredVersion "1.2.0" @SkipPublisherCheck

    Write-Host "Installing BuildHelpers"
    Install-Module "BuildHelpers" @AllowClobber
    Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -ErrorAction SilentlyContinue

    Write-Host "Installing Pester"
    Install-Module "Pester" -RequiredVersion "4.1.1" @SkipPublisherCheck

    Write-Host "Installing platyPS"
    Install-Module "platyPS"

    Write-Host "Installing PSScriptAnalyzer"
    Install-Module "PSScriptAnalyzer"
}

task Init {
    Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -ErrorAction SilentlyContinue

    $PSModulePath = $env:PSModulePath -split ([IO.Path]::PathSeparator)
    if ($env:BHBuildOutput -notin $PSModulePath) {
        $PSModulePath += $env:BHBuildOutput
        $env:PSModulePath = $PSModulePath -join ([IO.Path]::PathSeparator)
    }
}
#endregion Setup

#region HarmonizeVariables
switch ($true) {
    {$env:APPVEYOR_JOB_ID} {
        $CI = "AppVeyor"
        $OS = "Windows"
    }
    {$env:TRAVIS} {
        $CI = "Travis"
        $OS = $env:TRAVIS_OS_NAME
    }
    { (-not($env:APPVEYOR_JOB_ID)) -and (-not($env:TRAVIS)) } {
        $CI = "local"
    }
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
task ShowDebug Init, {
    Write-Build Gray
    Write-Build Gray ('Project name:               {0}' -f $env:BHProjectName)
    Write-Build Gray ('Project root:               {0}' -f $env:BHProjectPath)
    Write-Build Gray ('Branch:                     {0}' -f $env:BHBranchName)
    Write-Build Gray ('Commit:                     {0}' -f $env:APPVEYOR_REPO_COMMIT)
    Write-Build Gray ('  - Author:                 {0}' -f $env:APPVEYOR_REPO_COMMIT_AUTHOR)
    Write-Build Gray ('  - Time:                   {0}' -f $env:APPVEYOR_REPO_COMMIT_TIMESTAMP)
    Write-Build Gray ('  - Message:                {0}' -f $env:APPVEYOR_REPO_COMMIT_MESSAGE)
    Write-Build Gray ('  - Extended message:       {0}' -f $env:APPVEYOR_REPO_COMMIT_MESSAGE_EXTENDED)
    Write-Build Gray ('Pull request number:        {0}' -f $env:APPVEYOR_PULL_REQUEST_NUMBER)
    Write-Build Gray ('Pull request title:         {0}' -f $env:APPVEYOR_PULL_REQUEST_TITLE)
    Write-Build Gray ('AppVeyor build ID:          {0}' -f $env:APPVEYOR_BUILD_ID)
    Write-Build Gray ('AppVeyor build number:      {0}' -f $env:APPVEYOR_BUILD_NUMBER)
    Write-Build Gray ('AppVeyor build version:     {0}' -f $env:APPVEYOR_BUILD_VERSION)
    Write-Build Gray ('AppVeyor job ID:            {0}' -f $env:APPVEYOR_JOB_ID)
    Write-Build Gray ('Build triggered from tag?   {0}' -f $env:APPVEYOR_REPO_TAG)
    Write-Build Gray ('  - Tag name:               {0}' -f $env:APPVEYOR_REPO_TAG_NAME)
    Write-Build Gray ""
    Write-Build Gray ('PowerShell version:         {0}' -f $PSVersionTable.PSVersion.ToString())
    Write-Build Gray ('OS:                         {0}' -f $OS)
    Write-Build Gray ('OS Version:                 {0}' -f $OSVersion)
    Write-Build Gray ""
    Write-Build Gray (Get-Item ENV:BH* | Out-String)
}
#endregion DebugInformation

#region DependecyTasks
# Synopsis: Install pandoc to ./Tools/
task InstallPandoc {
    # Setup
    $Script:OriginalTlsSettings = [Net.ServicePointManager]::SecurityProtocol
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    if (-not (Test-Path "$BuildRoot/Tools")) {
        $null = New-Item -Path "$BuildRoot/Tools" -ItemType Directory
    }

    if ($OS -like "Windows*") {
        $path = $env:Path -split ([IO.Path]::PathSeparator)
        if ("$BuildRoot/Tools" -notin $path) {
            $path += Join-path $BuildRoot "Tools"
            $env:Path = $path -join ([IO.Path]::PathSeparator)
        }
    }

    $pandocVersion = $false
    try {
        $pandocVersion = & { pandoc --version }
    }
    catch { }
    If (-not ($pandocVersion)) {

        $installationFile = "$([System.IO.Path]::GetTempPath()){0}"

        # Get latest bits
        switch -regex ($OS) {
            "^[wW]indows" {
                $latestRelease = "https://github.com/jgm/pandoc/releases/download/1.19.2.1/pandoc-1.19.2.1-windows.msi"
                Invoke-WebRequest -Uri $latestRelease -OutFile ($installationFile -f "pandoc.msi")

                # Extract bits
                $extractionPath = "$([System.IO.Path]::GetTempPath())pandoc"
                $null = New-Item -Path $extractionPath -ItemType Directory -Force
                Start-Process -Wait -FilePath msiexec.exe -ArgumentList " /qn /a `"$($installationFile -f "pandoc.msi")`" targetdir=`"$extractionPath`""

                # Move to Tools folder
                Copy-Item -Path "$extractionPath/Pandoc/pandoc.exe" -Destination "$BuildRoot/Tools/"
                Copy-Item -Path "$extractionPath/Pandoc/pandoc-citeproc.exe" -Destination "$BuildRoot/Tools/"

                # Clean
                Remove-Item -Path ($installationFile -f "pandoc.msi") -Force -ErrorAction SilentlyContinue
                Remove-Item -Path $extractionPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            "^[lL]inux" {
                $latestRelease = "https://github.com/jgm/pandoc/releases/download/1.19.2.1/pandoc-1.19.2.1-1-amd64.deb"
                Invoke-WebRequest -Uri $latestRelease -OutFile ($installationFile -f "pandoc.deb")

                sudo dpkg -i $($installationFile -f "pandoc.deb")

                Remove-Item -Path ($installationFile -f "pandoc.deb") -Force -ErrorAction SilentlyContinue
            }
            "osx" {
                $latestRelease = "https://github.com/jgm/pandoc/releases/download/1.19.2.1/pandoc-1.19.2.1-osx.pkg"
                Invoke-WebRequest -Uri $latestRelease -OutFile ($installationFile -f "pandoc.pkg")

                sudo installer -pkg $($installationFile -f "pandoc.pkg") -target /

                Remove-Item -Path ($installationFile -f "pandoc.deb") -Force -ErrorAction SilentlyContinue
            }
        }
    }

    [Net.ServicePointManager]::SecurityProtocol = $Script:OriginalTlsSettings

    $out = & { pandoc --version }
    if (-not($out)) {throw "Could not install pandoc"}
}
#endregion DependecyTasks

#region BuildRelease
# Synopsis: Build shippable release
task Build GenerateRelease, ConvertMarkdown, UpdateManifest

# Synopsis: Generate ./Release structure
task GenerateRelease Init, CreateHelp, {
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
    BuildHelpers\Update-Metadata -Path "$env:BHBuildOutput/PSScriptAnalyzerSettings.psd1" -PropertyName ExcludeRules -Value ''
}

# Synopsis: Use PlatyPS to generate External-Help
task CreateHelp -If (Get-ChildItem "$BuildRoot/docs/en-US/commands" -ErrorAction SilentlyContinue) {
    Import-Module platyPS -Force
    foreach ($locale in (Get-ChildItem "$BuildRoot/docs" -Attribute Directory)) {
        New-ExternalHelp -Path "$($locale.FullName)" -OutputPath "$env:BHModulePath/$($locale.Basename)" -Force
        New-ExternalHelp -Path "$($locale.FullName)/commands" -OutputPath "$env:BHModulePath/$($locale.Basename)" -Force
    }
    Remove-Module platyPS
}

# Synopsis: Update the manifest of the module
task UpdateManifest GetVersion, {
    Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
    Import-Module $env:BHPSModuleManifest -Force
    $ModuleAlias = @(Get-Alias | Where-Object {$_.ModuleName -eq "$env:BHProjectName"})

    Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
    Import-Module $env:BHProjectName -Force

    Remove-Module BuildHelpers -ErrorAction SilentlyContinue
    Import-Module BuildHelpers -Force

    BuildHelpers\Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -PropertyName ModuleVersion -Value $script:Version
    # BuildHelpers\Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -PropertyName FileList -Value (Get-ChildItem "$env:BHBuildOutput/$env:BHProjectName" -Recurse).Name
    if ($ModuleAlias) {
        BuildHelpers\Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -PropertyName AliasesToExport -Value @($ModuleAlias.Name)
    }
    else {
        BuildHelpers\Update-Metadata -Path "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -PropertyName AliasesToExport -Value ''
    }
    BuildHelpers\Set-ModuleFunctions -Name "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -FunctionsToExport ([string[]](Get-ChildItem "$env:BHBuildOutput/$env:BHProjectName/Public/*.ps1").BaseName)
}

task GetVersion {
    $manifestContent = Get-Content -Path "$env:BHBuildOutput/$env:BHProjectName/$env:BHProjectName.psd1" -Raw
    if ($manifestContent -notmatch '(?<=ModuleVersion\s+=\s+'')(?<ModuleVersion>.*)(?='')') {
        throw "Module version was not found in manifest file,"
    }

    $currentVersion = [Version] $Matches.ModuleVersion
    if ($env:APPVEYOR_BUILD_NUMBER) {
        $newRevision = $env:APPVEYOR_BUILD_NUMBER
    }
    else {
        $newRevision = 0
    }
    $script:Version = New-Object -TypeName System.Version -ArgumentList $currentVersion.Major,
    $currentVersion.Minor,
    $newRevision
}

# Synopsis: Convert markdown files to HTML.
# <http://johnmacfarlane.net/pandoc/>
$ConvertMarkdown = @{
    Inputs  = { Get-ChildItem "$env:BHBuildOutput/$env:BHProjectName/*.md" -Recurse }
    Outputs = {process {
            [System.IO.Path]::ChangeExtension($_, 'htm')
        }
    }
}
# Synopsis: Converts *.md and *.markdown files to *.htm
task ConvertMarkdown -Partial @ConvertMarkdown InstallPandoc, {
    process {
        Write-Build Green "Converting File: $_"
        pandoc $_ --standalone --from=markdown_github "--output=$2"
    }
}
#endregion BuildRelease

#region Test
task Test Init, {
    assert { Test-Path $env:BHBuildOutput -PathType Container }

    Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue

    $Params = @{
        Path    = "$env:BHBuildOutput/$env:BHProjectName"
        Include = '*.ps1', '*.psm1'
        Recurse = $True
        # Exclude = $CodeCoverageExclude
    }
    $CodeCoverageFiles = Get-ChildItem @Params

    try {
        $parameter = @{
            Script       = "$env:BHBuildOutput/Tests/*"
            Tag          = $Tag
            ExcludeTag   = $ExcludeTag
            PassThru     = $true
            OutputFile   = "$BuildRoot/TestResult.xml"
            OutputFormat = "NUnitXml"
            CodeCoverage = $CodeCoverageFiles
        }
        $TestResults = Invoke-Pester @parameter

        if ($null -ne $CodeCoverageFiles) {
            $CoveragePercent = $TestResults.CodeCoverage.NumberOfCommandsExecuted / $TestResults.CodeCoverage.NumberOfCommandsAnalyzed
            Write-Build Gray " "
            Write-Build Gray "Code coverage Details"
            Write-Build Gray ("   Files:             {0:N0}" -f $TestResults.CodeCoverage.NumberOfFilesAnalyzed)
            Write-Build Gray ("   Commands Analyzed: {0:N0}" -f $TestResults.CodeCoverage.NumberOfCommandsAnalyzed)
            Write-Build Gray ("   Commands Hit:      {0:N0}" -f $TestResults.CodeCoverage.NumberOfCommandsExecuted)
            Write-Build Gray ("   Commands Missed:   {0:N0}" -f $TestResults.CodeCoverage.NumberOfCommandsMissed)
            Write-Build Gray ("   Coverage:          {0:P2}" -f $CoveragePercent)

            # if ($CoveragePercent -lt 0.90) {
            #     $Message = "Coverage {0:P2} is below 90%" -f $CoveragePercent
            #     Write-Error $Message
            # }
        }

        If ('AppVeyor' -eq $env:BHBuildSystem) {
            BuildHelpers\Add-TestResultToAppveyor -TestFile "$BuildRoot/TestResult.xml"

            Import-Module "./Tools/Modules/CodeCovIo"
            $Params = @{
                CodeCoverage = $TestResults.CodeCoverage
                RepoRoot     = $env:BHBuildOutput
            }
            $CodeCovJsonPath = Export-CodeCovIoJson @Params
            Invoke-UploadCoveCoveIoReport -Path $CodeCovJsonPath
            Remove-Module CodeCovIo
        }

        assert ($TestResults.FailedCount -eq 0) "$($TestResults.FailedCount) Pester test(s) failed."
    }
    catch {
        throw $_
    }
}, RemoveTestResults
#endregion

#region Publish
function allJobsFinished {
    param()
    $buildData = Get-AppVeyorBuild
    $lastJob = ($buildData.build.jobs | Select-Object -Last 1).jobId

    if ($lastJob -ne $env:APPVEYOR_JOB_ID) {
        return $false
    }

    write-host "[IDLE] :: waiting for other jobs to complete"

    [datetime]$stop = ([datetime]::Now).AddMinutes($env:TimeOutMins)

    do {
        $project = Get-AppVeyorBuild
        $continue = @()
        $project.build.jobs | Where-Object {$_.jobId -ne $env:APPVEYOR_JOB_ID} | Foreach-Object {
            $job = $_
            switch -regex ($job.status) {
                "failed" { throw "AppVeyor's Job ($($job.jobId)) failed." }
                "(running|success)" { $continue += $true; continue }
                Default { $continue += $false; Write-Host "new state: $_.status" }
            }
        }
        if ($false -notin $continue) { return $true }
        Start-sleep 5
    } while (([datetime]::Now) -lt $stop)

    throw "Test jobs were not finished in $env:TimeOutMins minutes"
}

$shouldDeploy = (
    # only deploy from AppVeyor
    ('AppVeyor' -eq $env:BHBuildSystem) -and
    # only deploy from last Job
    (allJobsFinished) -and
    # only deploy master branch
    ('master' -eq $env:BHBranchName) -and
    # it cannot be a PR
    (-not ($env:APPVEYOR_PULL_REQUEST_NUMBER)) -and
    # it cannot have a commit message that contains "skip-deploy"
    ($env:BHCommitMessage -notlike '*skip-deploy*')
)
# Synopsis: Publish a new release on github and the PSGallery
task Deploy -If $shouldDeploy Init, RemoveMarkdown, RemoveConfig, PublishToGallery

# Synipsis: Publish the $release to the PSGallery
task PublishToGallery {
    assert ($env:PSGalleryAPIKey) "No key for the PSGallery"

    Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
    Import-Module $env:BHProjectName -ErrorAction Stop
    Publish-Module -Name $env:BHProjectName -NuGetApiKey $env:PSGalleryAPIKey
}
#endregion Publish

#region Cleaning tasks
# Synopsis: Clean the working dir
task Clean RemoveGeneratedFiles

# Synopsis: Remove generated and temp files.
task RemoveGeneratedFiles {
    $itemsToRemove = @(
        "Release"
        "*.htm"
        "TestResult.xml"
    )
    Remove-Item $itemsToRemove -Force -Recurse -ErrorAction 0
}, RemoveTestResults

task RemoveTestResults {
    Remove-Item "TestResult.xml" -Force -ErrorAction 0
}

# Synopsis: Remove Markdown files from Release
task RemoveMarkdown -If { Get-ChildItem "$env:BHBuildOutput/$env:BHProjectName/*.md" -Recurse } {
    Remove-Item -Path "$env:BHBuildOutput/$env:BHProjectName" -Include "*.md" -Recurse
}

task RemoveConfig {
    Get-ChildItem $env:BHBuildOutput -Filter "config.xml" -Recurse | Remove-Item -Force
}
#endregion

task . ShowDebug, Clean, Build, Test, Deploy

Remove-Item -Path Env:\BH*
