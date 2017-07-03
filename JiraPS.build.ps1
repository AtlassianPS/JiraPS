[CmdletBinding()]
param()

$DebugPreference = "SilentlyContinue"
$WarningPreference = "Continue"
if ($PSBoundParameters.ContainsKey('Verbose')) {
    $VerbosePreference = "Continue"
}

Import-Module BuildHelpers
# Write-Host "BuildHelpers environment details:`n$(Get-Item env:BH* | Out-String)`n" -ForegroundColor Cyan

# Ensure Invoke-Build works in the most strict mode.
Set-StrictMode -Version Latest

# region satisfy dependencies
# task {
# Import dependencies if missing
# }

# Synopsis: Install pandoc to .\Tools\
task InstallPandoc -If (-not (Test-Path Tools\pandoc.exe)) {
    # Setup
    if (-not (Test-Path "$BuildRoot\Tools")) {
        $null = New-Item -Path "$BuildRoot\Tools" -ItemType Directory
    }

    Write-Build Gray "Downloading pandoc"
    # Get latest bits
    $latestRelease = "https://github.com/jgm/pandoc/releases/download/1.19.2.1/pandoc-1.19.2.1-windows.msi"
    Invoke-WebRequest -Uri $latestRelease -OutFile "$($env:temp)\pandoc.msi"

    Write-Build Gray "Extracting pandoc to $($env:temp)\pandoc"
    # Extract bits
    $null = New-Item -Path $env:temp\pandoc -ItemType Directory -Force
    Start-Process -Wait -FilePath msiexec.exe -ArgumentList " /qn /i `"$($env:temp)\pandoc.msi`" targetdir=`"$($env:temp)\pandoc\`""

    Write-Build Gray "$((Get-ChildItem $env:temp\pandoc) | Out-String)"
    Write-Build Gray "Moving pandoc"
    # Move to Tools folder
    Copy-Item -Path "$($env:temp)\pandoc\pandoc.exe" -Destination "$BuildRoot\Tools\"
    Copy-Item -Path "$($env:temp)\pandoc\pandoc-citeproc.exe" -Destination "$BuildRoot\Tools\"

    Write-Build Gray "Removing pandoc"
    # Clean
    Remove-Item -Path "$($env:temp)\pandoc" -Recurse -Force
}
# endregion

# region test
# Synopsis: Using the "Fast" Test Suit
task RapidTest GitStatus, PesterTests
# Synopsis: Using the complete Test Suit, which includes all supported Powershell versions
task FullTest GitStatus, TestVersions

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
    Install-Module Pester, PSScriptAnalyzer -Force
    try {
        $result = Invoke-Pester -PassThru -OutputFile $BuildRoot\TestResult.xml
        if ($env:BHBuildSystem -eq "AppVeyor") {
            Add-TestResultToAppveyor -TestFile "$BuildRoot\TestResult.xml"
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
task Package GenerateRelease, UpdateManifest, GenerateDocs

# Synopsis: Generate .\Release structure
task GenerateRelease {
    # Setup
    if (-not (Test-Path "$BuildRoot\Release")) {
        $null = New-Item -Path "$BuildRoot\Release" -ItemType Directory
    }

    # Copy module
    Copy-Item -Path "$BuildRoot\JiraPS\*" -Destination "$BuildRoot\Release" -Recurse -Force
    # Copy additional files
    $additionalFiles = @(
        "$BuildRoot\CHANGELOG.md"
        "$BuildRoot\LICENSE"
        "$BuildRoot\README.md"
    )
    Copy-Item -Path $additionalFiles -Destination "$BuildRoot\Release" -Force
}

# Synopsis: Update the manifest of the module
task UpdateManifest GetVersion, {
    Update-Metadata -Path "$BuildRoot\Release\JiraPS.psd1" -PropertyName ModuleVersion -Value $script:Version
    Update-Metadata -Path "$BuildRoot\Release\JiraPS.psd1" -PropertyName FileList -Value (Get-ChildItem $BuildRoot\Release -Recurse).Name
    Set-ModuleFunctions -Name "$BuildRoot\Release\JiraPS.psd1"
}

task GetVersion {
    $manifestContent = Get-Content -Path "$BuildRoot\Release\JiraPS.psd1" -Raw
    if ($manifestContent -notmatch '(?<=ModuleVersion\s+=\s+'')(?<ModuleVersion>.*)(?='')') {
        throw "Module version was not found in manifest file,"
    }

    $currentVersion = [Version] $Matches.ModuleVersion
    if ($env:BHBuildNumber) {
        $newRevision = $env:BHBuildNumber
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
task GenerateDocs GenerateMarkdown, ConvertMarkdown, RemoveMarkdown

# Synopsis: Generate markdown documentation with platyPS
task GenerateMarkdown {
    Install-Module platyPS -Force
    Import-Module platyPS -Force
    Import-Module "$BuildRoot\Release\JiraPS.psd1" -Force
    $null = New-MarkdownHelp -Module JiraPS -OutputFolder "$BuildRoot\Release\docs" -Force
    Remove-Module JiraPS, platyPS
}

# Synopsis: Convert markdown files to HTML.
# <http://johnmacfarlane.net/pandoc/>
$ConvertMarkdown = @{
    Inputs  = { Get-ChildItem "$BuildRoot\Release\*.md" -Recurse }
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
task Publish -If ($env:BHBranchName -eq 'master' -and ($env:APPVEYOR_PULL_REQUEST_NUMBER)) {
    Remove-Module JiraPS -ErrorAction SilentlyContinue
    Import-Module $BuildRoot\Release\JiraPS.psd1
}, PushRelease, PublishToGallery

task PublishToGallery {
    assert ($env:PSGalleryAPIKey) "No key for the PSGallery"

    Publish-Module JiraPS -NuGetApiKey $env:PSGalleryAPIKey
}

# Synopsis: Push with a version tag.
task PushRelease GetVersion, {
    $changes = exec { git status --short }
    assert (!$changes) "Please, commit changes."

    exec { git push }
    exec { git tag -a "v$Version" -m "v$Version" }
    exec { git push origin "v$Version" }
}
# endregion

#region Cleaning tasks
task Clean RemoveGeneratedFiles, RemoveBHEnvironment
# Synopsis: Remove generated and temp files.
task RemoveGeneratedFiles -If (-not $env:BHBuildSystem -ne "Unknown") {
    $itemsToRemove = @(
        'Release'
        '*.htm'
        'TestResult.xml'
    )
    Remove-Item $itemsToRemove -Force -Recurse -ErrorAction 0
}

# Synopsis: Remove BuildHelper Environment
task RemoveBHEnvironment {
    Remove-Item -Path env:\BH*
}

# Synopsis: Remove Markdown files from Release
task RemoveMarkdown -Inputs { Get-Item "$BuildRoot\Release\*.md" } {
    Remove-Item -Path "$BuildRoot\Release" -Include "*.md" -Recurse
}
# endregion

task . Clean, Test, Package, Publish
task Test RapidTest
task Release Clean, FullTest, Package, Publish
task Build Clean, Package, Publish
