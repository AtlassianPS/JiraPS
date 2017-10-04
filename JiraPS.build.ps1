[CmdletBinding()]
param()

$DebugPreference = "SilentlyContinue"
$WarningPreference = "Continue"
if ($PSBoundParameters.ContainsKey('Verbose')) {
    $VerbosePreference = "Continue"
}

if (!($env:releasePath)) {
    $releasePath = "$BuildRoot\Release"
}
else {
    $releasePath = $env:releasePath
}
$env:PSModulePath = "$($env:PSModulePath);$releasePath"

Import-Module BuildHelpers

# Ensure Invoke-Build works in the most strict mode.
Set-StrictMode -Version Latest

# region debug information
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

# Synopsis: Install pandoc to .\Tools\
task InstallPandoc -If (-not (Test-Path Tools\pandoc.exe)) {
    # Setup
    if (-not (Test-Path "$BuildRoot\Tools")) {
        $null = New-Item -Path "$BuildRoot\Tools" -ItemType Directory
    }

    # Get latest bits
    $latestRelease = "https://github.com/jgm/pandoc/releases/download/1.19.2.1/pandoc-1.19.2.1-windows.msi"
    Invoke-WebRequest -Uri $latestRelease -OutFile "$($env:temp)\pandoc.msi"

    # Extract bits
    $null = New-Item -Path $env:temp\pandoc -ItemType Directory -Force
    Start-Process -Wait -FilePath msiexec.exe -ArgumentList " /qn /a `"$($env:temp)\pandoc.msi`" targetdir=`"$($env:temp)\pandoc\`""

    # Move to Tools folder
    Copy-Item -Path "$($env:temp)\pandoc\Pandoc\pandoc.exe" -Destination "$BuildRoot\Tools\"
    Copy-Item -Path "$($env:temp)\pandoc\Pandoc\pandoc-citeproc.exe" -Destination "$BuildRoot\Tools\"

    # Clean
    Remove-Item -Path "$($env:temp)\pandoc" -Recurse -Force
}
# endregion

# region test
task Test RapidTest

# Synopsis: Using the "Fast" Test Suit
task RapidTest PesterTests
# Synopsis: Using the complete Test Suit, which includes all supported Powershell versions
task FullTest TestVersions

# Synopsis: Warn about not empty git status if .git exists.
task GitStatus -If (Test-Path .git) {
    $status = exec { git status -s }
    if ($status) {
        Write-Warning "Git status: $($status -join ', ')"
    }
}

task TestVersions TestPS3, TestPS4, TestPS4, TestPS5
task TestPS3 {
    exec {powershell.exe -Version 3 -NoProfile Invoke-Build PesterTests}
}
task TestPS4 {
    exec {powershell.exe -Version 4 -NoProfile Invoke-Build PesterTests}
}
task TestPS5 {
    exec {powershell.exe -Version 5 -NoProfile Invoke-Build PesterTests}
}

# Synopsis: Invoke Pester Tests
task PesterTests {
    # Ensure expected environment
    Remove-Module JiraPS -ErrorAction SilentlyContinue
    $global:SuppressImportModule = $false

    try {
        $result = Invoke-Pester -PassThru -OutputFile $BuildRoot\TestResult.xml
        if ($env:APPVEYOR_PROJECT_NAME) {
            Add-TestResultToAppveyor -TestFile "$BuildRoot\TestResult.xml"
            Remove-Item "$BuildRoot\TestResult.xml" -Force
        }
        assert ($result.FailedCount -eq 0) "$($result.FailedCount) Pester test(s) failed."
    }
    catch {
        throw
    }
}
# endregion

# region build
# Synopsis: Build shippable release
task Build GenerateRelease, GenerateDocs, UpdateManifest

# Synopsis: Generate .\Release structure
task GenerateRelease {
    # Setup
    if (-not (Test-Path "$releasePath\JiraPS")) {
        $null = New-Item -Path "$releasePath\JiraPS" -ItemType Directory
    }

    # Copy module
    Copy-Item -Path "$BuildRoot\JiraPS\*" -Destination "$releasePath\JiraPS" -Recurse -Force
    # Copy additional files
    $additionalFiles = @(
        "$BuildRoot\CHANGELOG.md"
        "$BuildRoot\LICENSE"
        "$BuildRoot\README.md"
    )
    Copy-Item -Path $additionalFiles -Destination "$releasePath\JiraPS" -Force
}

# Synopsis: Update the manifest of the module
task UpdateManifest GetVersion, {
    $ModuleAlias = (Get-Alias | Where source -eq JiraPS)

    Remove-Module JiraPS -ErrorAction SilentlyContinue
    Import-Module "$releasePath\JiraPS\JiraPS.psd1"
    Update-Metadata -Path "$releasePath\JiraPS\JiraPS.psd1" -PropertyName ModuleVersion -Value $script:Version
    # Update-Metadata -Path "$releasePath\JiraPS\JiraPS.psd1" -PropertyName FileList -Value (Get-ChildItem $releasePath\JiraPS -Recurse).Name
    if ($ModuleAlias) {
        Update-Metadata -Path "$releasePath\JiraPS\JiraPS.psd1" -PropertyName AliasesToExport -Value @($ModuleAlias.Name)
    }
    Set-ModuleFunctions -Name "$releasePath\JiraPS\JiraPS.psd1" -FunctionsToExport ([string[]](Get-ChildItem "$releasePath\JiraPS\public\*.ps1").BaseName)
}

task GetVersion {
    $manifestContent = Get-Content -Path "$releasePath\JiraPS\JiraPS.psd1" -Raw
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
    $currentVersion.Build,
    $newRevision
}

# Synopsis: Generate documentation
task GenerateDocs GenerateMarkdown, ConvertMarkdown

# Synopsis: Generate markdown documentation with platyPS
task GenerateMarkdown {
    Import-Module platyPS -Force
    Import-Module "$releasePath\JiraPS\JiraPS.psd1" -Force
    $null = New-MarkdownHelp -Module JiraPS -OutputFolder "$releasePath\JiraPS\docs" -Force
    Remove-Module JiraPS, platyPS
}

# Synopsis: Convert markdown files to HTML.
# <http://johnmacfarlane.net/pandoc/>
$ConvertMarkdown = @{
    Inputs  = { Get-ChildItem "$releasePath\JiraPS\*.md" -Recurse }
    Outputs = {process {
            [System.IO.Path]::ChangeExtension($_, 'htm')
        }
    }
}
# Synopsis: Converts *.md and *.markdown files to *.htm
task ConvertMarkdown -Partial @ConvertMarkdown InstallPandoc, {process {
        Write-Build Green "Converting File: $_"
        exec { Tools\pandoc.exe $_ --standalone --from=markdown_github "--output=$2" }
    }
}
# endregion

# region publish
task Deploy -If ($env:APPVEYOR_REPO_BRANCH -eq 'master' -and (-not($env:APPVEYOR_PULL_REQUEST_NUMBER))) RemoveMarkdown, {
    Remove-Module JiraPS -ErrorAction SilentlyContinue
}, PublishToGallery

task PublishToGallery {
    assert ($env:PSGalleryAPIKey) "No key for the PSGallery"

    Import-Module $releasePath\JiraPS\JiraPS.psd1 -ErrorAction Stop
    Publish-Module -Name JiraPS -NuGetApiKey $env:PSGalleryAPIKey
}

# Synopsis: Push with a version tag.
task PushRelease GitStatus, GetVersion, {
    # Done in appveyor.yml with deploy provider.
    # This is needed, as I don't know how to athenticate (2-factor) in here.
    exec { git checkout master }
    $changes = exec { git status --short }
    assert (!$changes) "Please, commit changes."

    exec { git push }
    exec { git tag -a "v$Version" -m "v$Version" }
    exec { git push origin "v$Version" }
}
# endregion

#region Cleaning tasks
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
task RemoveMarkdown -If { Get-ChildItem "$releasePath\JiraPS\*.md" -Recurse } {
    Remove-Item -Path "$releasePath\JiraPS" -Include "*.md" -Recurse
}
# endregion

task . ShowDebug, Test, Build, Deploy, Clean
