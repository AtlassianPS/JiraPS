[CmdletBinding()]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
param(
    $ModuleName = (Split-Path $BuildRoot -Leaf),
    $releasePath = "$BuildRoot/Release"
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

$PSModulePath = $env:PSModulePath -split ([IO.Path]::PathSeparator)
if ($releasePath -notin $PSModulePath) {
    $PSModulePath += $releasePath
    $env:PSModulePath = $PSModulePath -join ([IO.Path]::PathSeparator)
}

Set-StrictMode -Version Latest

# Synopsis: Create an initial environment for developing on the module
task SetUp InstallDependencies, Build

# Synopsis: Install all module used for the development of this module
task InstallDependencies InstallPandoc, {
    Install-Module platyPS -Scope CurrentUser -Force
    Install-Module Pester -Scope CurrentUser -Force
    Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
}
#endregion Setup

#region DebugInformation
task ShowDebug {
    Write-Build Gray
    Write-Build Gray ('Project name:               {0}' -f $env:APPVEYOR_PROJECT_NAME)
    Write-Build Gray ('Project root:               {0}' -f $env:APPVEYOR_BUILD_FOLDER)
    Write-Build Gray ('Repo name:                  {0}' -f $env:APPVEYOR_REPO_NAME)
    Write-Build Gray ('Branch:                     {0}' -f $env:APPVEYOR_REPO_BRANCH)
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
    Write-Build Gray ('PowerShell version:         {0}' -f $PSVersionTable.PSVersion.ToString())
    Write-Build Gray
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
task GenerateRelease CreateHelp, {
    # Setup
    if (-not (Test-Path "$releasePath/$ModuleName")) {
        $null = New-Item -Path "$releasePath/$ModuleName" -ItemType Directory
    }

    # Copy module
    Copy-Item -Path "$BuildRoot/$ModuleName/*" -Destination "$releasePath/$ModuleName" -Recurse -Force
    # Copy additional files
    Copy-Item -Path @(
        "$BuildRoot/CHANGELOG.md"
        "$BuildRoot/LICENSE"
        "$BuildRoot/README.md"
    ) -Destination "$releasePath/$ModuleName" -Force
    # Copy Tests
    $null = New-Item -Path "$releasePath/Tests" -ItemType Directory -ErrorAction SilentlyContinue
    Copy-Item -Path "$BuildRoot/Tests/*.ps1" -Destination "$releasePath/Tests" -Recurse -Force
    # Include Analyzer Settings
    Copy-Item -Path "$BuildRoot/PSScriptAnalyzerSettings.psd1" -Destination "$releasePath/PSScriptAnalyzerSettings.psd1" -Force
    BuildHelpers\Update-Metadata -Path "$releasePath/PSScriptAnalyzerSettings.psd1" -PropertyName ExcludeRules -Value ''
}

# Synopsis: Use PlatyPS to generate External-Help
task CreateHelp -If (Get-ChildItem "$BuildRoot/docs/en-US/commands" -ErrorAction SilentlyContinue) {
    Import-Module platyPS -Force
    foreach ($locale in (Get-ChildItem "$BuildRoot/docs" -Attribute Directory)) {
        New-ExternalHelp -Path "$($locale.FullName)" -OutputPath "$BuildRoot/$ModuleName/$($locale.Basename)" -Force
        New-ExternalHelp -Path "$($locale.FullName)/commands" -OutputPath "$BuildRoot/$ModuleName/$($locale.Basename)" -Force
    }
    Remove-Module $ModuleName, platyPS
}

# Synopsis: Update the manifest of the module
task UpdateManifest GetVersion, {
    Remove-Module $ModuleName -ErrorAction SilentlyContinue
    Import-Module "$BuildRoot/$ModuleName/$ModuleName.psd1" -Force
    $ModuleAlias = @(Get-Alias | Where-Object {$_.ModuleName -eq "$ModuleName"})

    Remove-Module $ModuleName -ErrorAction SilentlyContinue
    Import-Module $ModuleName -Force

    Remove-Module BuildHelpers -ErrorAction SilentlyContinue
    Import-Module BuildHelpers -Force

    BuildHelpers\Update-Metadata -Path "$releasePath/$ModuleName/$ModuleName.psd1" -PropertyName ModuleVersion -Value $script:Version
    # BuildHelpers\Update-Metadata -Path "$releasePath/$ModuleName/$ModuleName.psd1" -PropertyName FileList -Value (Get-ChildItem "$releasePath/$ModuleName" -Recurse).Name
    if ($ModuleAlias) {
        BuildHelpers\Update-Metadata -Path "$releasePath/$ModuleName/$ModuleName.psd1" -PropertyName AliasesToExport -Value @($ModuleAlias.Name)
    }
    else {
        BuildHelpers\Update-Metadata -Path "$releasePath/$ModuleName/$ModuleName.psd1" -PropertyName AliasesToExport -Value ''
    }
    BuildHelpers\Set-ModuleFunctions -Name "$releasePath/$ModuleName/$ModuleName.psd1" -FunctionsToExport ([string[]](Get-ChildItem "$releasePath/$ModuleName/public/*.ps1").BaseName)
}

task GetVersion {
    $manifestContent = Get-Content -Path "$releasePath/$ModuleName/$ModuleName.psd1" -Raw
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
    Inputs  = { Get-ChildItem "$releasePath/$ModuleName/*.md" -Recurse }
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
task Test {
    assert { Test-Path "$BuildRoot/Release/" -PathType Container }

    Remove-Module $ModuleName -ErrorAction SilentlyContinue

    Remove-Module BuildHelpers -ErrorAction SilentlyContinue
    Import-Module BuildHelpers -Force

    try {
        $result = Invoke-Pester -Script "$BuildRoot/Release/Tests/*" -PassThru -OutputFile "$BuildRoot/TestResult.xml" -OutputFormat "NUnitXml"
        if ($env:APPVEYOR_PROJECT_NAME) {
            BuildHelpers\Add-TestResultToAppveyor -TestFile "$BuildRoot/TestResult.xml"
        }
        Remove-Item "$BuildRoot/TestResult.xml" -Force
        assert ($result.FailedCount -eq 0) "$($result.FailedCount) Pester test(s) failed."
    }
    catch {
        throw $_
    }
}
#endregion

#region Publish
$shouldDeploy = (
    # only deploy master branch
    ($env:APPVEYOR_REPO_BRANCH -eq 'master') -and
    # it cannot be a PR
    (-not ($env:APPVEYOR_PULL_REQUEST_NUMBER)) -and
    # it cannot have a commit message that contains "skip-deploy"
    ($env:APPVEYOR_REPO_COMMIT_MESSAGE -notlike '*skip-deploy*')
)
# Synopsis: Publish a new release on github and the PSGallery
task Deploy -If $shouldDeploy RemoveMarkdown, RemoveConfig, PublishToGallery

# Synipsis: Publish the $release to the PSGallery
task PublishToGallery {
    assert ($env:PSGalleryAPIKey) "No key for the PSGallery"

    Remove-Module $ModuleName -ErrorAction SilentlyContinue
    Import-Module $ModuleName -ErrorAction Stop
    Publish-Module -Name $ModuleName -NuGetApiKey $env:PSGalleryAPIKey
}
#endregion Publish

#region Cleaning tasks
# Synopsis: Clean the working dir
task Clean RemoveGeneratedFiles

# Synopsis: Remove generated and temp files.
task RemoveGeneratedFiles {
    $itemsToRemove = @(
        'Release'
        '*.htm'
        'TestResult.xml'
    )
    Remove-Item $itemsToRemove -Force -Recurse -ErrorAction 0
}

# Synopsis: Remove Markdown files from Release
task RemoveMarkdown -If { Get-ChildItem "$releasePath/$ModuleName/*.md" -Recurse } {
    Remove-Item -Path "$releasePath/$ModuleName" -Include "*.md" -Recurse
}

task RemoveConfig {
    Get-ChildItem $releasePath -Filter "config.xml" -Recurse | Remove-Item -Force
}
#endregion

task . ShowDebug, Clean, Build, Test, Deploy
