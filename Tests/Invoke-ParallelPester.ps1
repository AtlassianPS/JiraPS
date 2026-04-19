<#
.SYNOPSIS
    Runs Pester integration tests in parallel (PS7+) or sequentially (PS5.1).

.DESCRIPTION
    This script runs multiple Pester test files to support integration testing.
    On PowerShell 7+, files run concurrently using ForEach-Object -Parallel.
    On PowerShell 5.1, files run sequentially as a fallback.

    Each test file generates its own NUnit XML which is then merged into a single
    output file with full test-case details (names, durations, failure messages).

    NOTE: This script provides file-level parallelization. Pester 5's built-in
    -Parallel flag provides test-level parallelization within a single invocation.
    The file-level approach is used here for isolation between integration test
    files that may have conflicting global state or authentication sessions.

.PARAMETER Path
    Path to the directory containing test files, or an array of test file paths.
    Defaults to ./Tests/Integration/

.PARAMETER ThrottleLimit
    Maximum number of tests to run concurrently (PS7+ only). Defaults to 4.
    Ignored on PS5.1 which runs sequentially.

.PARAMETER Tag
    Only run tests with these tags.

.PARAMETER ExcludeTag
    Exclude tests with these tags.

.PARAMETER Output
    Output verbosity: None, Normal, Detailed, Diagnostic. Defaults to Normal.

.PARAMETER OutputPath
    Path to write merged NUnit XML test results. If not specified, no XML file is generated.

.EXAMPLE
    ./Tests/Invoke-ParallelPester.ps1

    Runs all integration tests with default settings.

.EXAMPLE
    ./Tests/Invoke-ParallelPester.ps1 -ThrottleLimit 6 -Tag 'Smoke'

    Runs smoke tests with up to 6 concurrent test files.

.EXAMPLE
    ./Tests/Invoke-ParallelPester.ps1 -OutputPath 'TestResults.xml'

    Runs tests and generates a merged NUnit XML report with full test details.

.NOTES
    On PowerShell 5.1, ThrottleLimit is ignored and tests run sequentially.
    For full parallelization support, use PowerShell 7+.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Interactive script with colored console output')]
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string[]]$Path = './Tests/Integration/',

    [Parameter()]
    [int]$ThrottleLimit = 4,

    [Parameter()]
    [string[]]$Tag,

    [Parameter()]
    [string[]]$ExcludeTag,

    [Parameter()]
    [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
    [string]$Output = 'Normal',

    [Parameter()]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

$canParallel = $PSVersionTable.PSVersion.Major -ge 7

if (-not $canParallel) {
    Write-Warning "PowerShell 5.1 detected: running tests sequentially. Use PowerShell 7+ for parallel execution."
}

$projectRoot = Split-Path -Parent $PSScriptRoot

$tempResultsDir = Join-Path ([System.IO.Path]::GetTempPath()) "JiraPS-TestResults-$(Get-Date -Format 'yyyyMMddHHmmss')"
if ($OutputPath) {
    if ($PSCmdlet.ShouldProcess($tempResultsDir, "Create temporary results directory")) {
        $null = New-Item -ItemType Directory -Path $tempResultsDir -Force
    }
}

$testFiles = @()
foreach ($p in $Path) {
    $resolvedPath = Resolve-Path $p -ErrorAction SilentlyContinue
    if ($resolvedPath) {
        if (Test-Path $resolvedPath -PathType Container) {
            $testFiles += Get-ChildItem -Path $resolvedPath -Filter '*.Tests.ps1' -File
        }
        else {
            $testFiles += Get-Item $resolvedPath
        }
    }
}

if ($testFiles.Count -eq 0) {
    Write-Warning "No test files found in: $Path"
    return
}

$executionMode = if ($canParallel) { "ThrottleLimit=$ThrottleLimit" } else { "sequential (PS 5.1)" }
Write-Host "Running $($testFiles.Count) test files ($executionMode)" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date

$runTestFile = {
    param($testFile, $projectRoot, $tagFilter, $excludeTagFilter, $outputVerbosity, $tempResultsDir, $generateXml)

    try {
        $envPath = Join-Path $projectRoot '.env'
        if (Test-Path $envPath) {
            Get-Content $envPath | ForEach-Object {
                if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
                if ($_ -match '^([^=]+)=(.*)$') {
                    $name = $matches[1].Trim()
                    $value = $matches[2]
                    if ($value -match '^([^#]*?)\s*#') { $value = $matches[1] }
                    $value = $value.Trim()
                    if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
                        ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                        $value = $value.Substring(1, $value.Length - 2)
                    }
                    if (-not [string]::IsNullOrEmpty($name)) {
                        [System.Environment]::SetEnvironmentVariable($name, $value)
                    }
                }
            }
        }

        Import-Module Pester -MinimumVersion 5.0 -Force
        Set-Location $projectRoot

        $config = New-PesterConfiguration
        $config.Run.Path = $testFile.FullName
        $config.Run.PassThru = $true
        $config.Output.Verbosity = $outputVerbosity

        if ($generateXml -and $tempResultsDir) {
            $config.TestResult.Enabled = $true
            $config.TestResult.OutputFormat = 'NUnitXml'
            $config.TestResult.OutputPath = Join-Path $tempResultsDir "$($testFile.BaseName).xml"
        }

        if ($tagFilter) { $config.Filter.Tag = $tagFilter }
        if ($excludeTagFilter) { $config.Filter.ExcludeTag = $excludeTagFilter }

        $result = Invoke-Pester -Configuration $config

        $failedTests = @()
        if ($result.FailedCount -gt 0) {
            foreach ($container in $result.Containers) {
                foreach ($block in $container.Blocks) {
                    foreach ($test in $block.Tests) {
                        if ($test.Result -eq 'Failed') {
                            $failedTests += [PSCustomObject]@{
                                Name         = $test.Name
                                ErrorMessage = if ($test.ErrorRecord) { $test.ErrorRecord[0].Exception.Message } else { 'Unknown error' }
                            }
                        }
                    }
                }
            }
        }

        [PSCustomObject]@{
            File        = $testFile.Name
            Passed      = $result.PassedCount
            Failed      = $result.FailedCount
            Skipped     = $result.SkippedCount
            Duration    = $result.Duration
            Success     = $result.FailedCount -eq 0
            FailedTests = $failedTests
            XmlPath     = if ($generateXml) { Join-Path $tempResultsDir "$($testFile.BaseName).xml" } else { $null }
        }
    }
    catch {
        [PSCustomObject]@{
            File        = $testFile.Name
            Passed      = 0
            Failed      = 1
            Skipped     = 0
            Duration    = [TimeSpan]::Zero
            Success     = $false
            Error       = $_.Exception.Message
            FailedTests = @([PSCustomObject]@{ Name = 'Script execution'; ErrorMessage = $_.Exception.Message })
            XmlPath     = $null
        }
    }
}

$results = @()
$generateXml = [bool]$OutputPath

if ($canParallel) {
    # Script blocks cannot be passed via $using:, so test execution is inlined
    $results = $testFiles | ForEach-Object -Parallel {
        $testFile = $_
        $projectRoot = $using:projectRoot
        $tagFilter = $using:Tag
        $excludeTagFilter = $using:ExcludeTag
        $outputVerbosity = $using:Output
        $tempResultsDir = $using:tempResultsDir
        $generateXml = $using:generateXml

        try {
            $envPath = Join-Path $projectRoot '.env'
            if (Test-Path $envPath) {
                Get-Content $envPath | ForEach-Object {
                    if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
                    if ($_ -match '^([^=]+)=(.*)$') {
                        $name = $matches[1].Trim()
                        $value = $matches[2]
                        if ($value -match '^([^#]*?)\s*#') { $value = $matches[1] }
                        $value = $value.Trim()
                        if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
                            ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                            $value = $value.Substring(1, $value.Length - 2)
                        }
                        if (-not [string]::IsNullOrEmpty($name)) {
                            [System.Environment]::SetEnvironmentVariable($name, $value)
                        }
                    }
                }
            }

            Import-Module Pester -MinimumVersion 5.0 -Force
            Set-Location $projectRoot

            $config = New-PesterConfiguration
            $config.Run.Path = $testFile.FullName
            $config.Run.PassThru = $true
            $config.Output.Verbosity = $outputVerbosity

            if ($generateXml -and $tempResultsDir) {
                $config.TestResult.Enabled = $true
                $config.TestResult.OutputFormat = 'NUnitXml'
                $config.TestResult.OutputPath = Join-Path $tempResultsDir "$($testFile.BaseName).xml"
            }

            if ($tagFilter) { $config.Filter.Tag = $tagFilter }
            if ($excludeTagFilter) { $config.Filter.ExcludeTag = $excludeTagFilter }

            $result = Invoke-Pester -Configuration $config

            $failedTests = @()
            if ($result.FailedCount -gt 0) {
                foreach ($container in $result.Containers) {
                    foreach ($block in $container.Blocks) {
                        foreach ($test in $block.Tests) {
                            if ($test.Result -eq 'Failed') {
                                $failedTests += [PSCustomObject]@{
                                    Name         = $test.Name
                                    ErrorMessage = if ($test.ErrorRecord) { $test.ErrorRecord[0].Exception.Message } else { 'Unknown error' }
                                }
                            }
                        }
                    }
                }
            }

            [PSCustomObject]@{
                File        = $testFile.Name
                Passed      = $result.PassedCount
                Failed      = $result.FailedCount
                Skipped     = $result.SkippedCount
                Duration    = $result.Duration
                Success     = $result.FailedCount -eq 0
                FailedTests = $failedTests
                XmlPath     = if ($generateXml) { Join-Path $tempResultsDir "$($testFile.BaseName).xml" } else { $null }
            }
        }
        catch {
            [PSCustomObject]@{
                File        = $testFile.Name
                Passed      = 0
                Failed      = 1
                Skipped     = 0
                Duration    = [TimeSpan]::Zero
                Success     = $false
                Error       = $_.Exception.Message
                FailedTests = @([PSCustomObject]@{ Name = 'Script execution'; ErrorMessage = $_.Exception.Message })
                XmlPath     = $null
            }
        }
    } -ThrottleLimit $ThrottleLimit
}
else {
    foreach ($testFile in $testFiles) {
        $results += & $runTestFile $testFile $projectRoot $Tag $ExcludeTag $Output $tempResultsDir $generateXml
    }
}

$endTime = Get-Date
$totalDuration = $endTime - $startTime

$totalPassed = 0
$totalFailed = 0
$totalSkipped = 0
$allFailedTests = @()

foreach ($r in $results) {
    $totalPassed += $r.Passed
    $totalFailed += $r.Failed
    $totalSkipped += $r.Skipped

    if ($r.Error) {
        Write-Host "[ERROR] $($r.File): $($r.Error)" -ForegroundColor Red
    }

    if ($r.FailedTests) {
        foreach ($ft in $r.FailedTests) {
            $allFailedTests += [PSCustomObject]@{
                File         = $r.File
                Test         = $ft.Name
                ErrorMessage = $ft.ErrorMessage
            }
        }
    }
}

if ($allFailedTests.Count -gt 0) {
    Write-Host ""
    Write-Host "========== FAILED TESTS ==========" -ForegroundColor Red
    foreach ($ft in $allFailedTests) {
        Write-Host "  $($ft.File)" -ForegroundColor Yellow -NoNewline
        Write-Host " :: " -NoNewline
        Write-Host "$($ft.Test)" -ForegroundColor White
        Write-Host "    $($ft.ErrorMessage)" -ForegroundColor DarkGray
    }
    Write-Host "==================================" -ForegroundColor Red
    Write-Host ""
}

Write-Host ""
Write-Host "========== TEST SUMMARY ==========" -ForegroundColor Cyan
Write-Host "  Total:   $($totalPassed + $totalFailed + $totalSkipped)" -ForegroundColor White
Write-Host "  Passed:  $totalPassed" -ForegroundColor Green
Write-Host "  Failed:  $totalFailed" -ForegroundColor $(if ($totalFailed -gt 0) { 'Red' } else { 'Green' })
Write-Host "  Skipped: $totalSkipped" -ForegroundColor Yellow
Write-Host "  Duration: $($totalDuration.ToString('hh\:mm\:ss\.fff'))" -ForegroundColor White
Write-Host "==================================" -ForegroundColor Cyan

if ($OutputPath -and (Test-Path $tempResultsDir)) {
    $xmlFiles = Get-ChildItem -Path $tempResultsDir -Filter '*.xml' -File

    if ($xmlFiles.Count -gt 0) {
        if ($PSCmdlet.ShouldProcess($OutputPath, "Merge $($xmlFiles.Count) test result files")) {
            $mergedDoc = [xml]'<?xml version="1.0" encoding="utf-8"?><test-results></test-results>'
            $root = $mergedDoc.DocumentElement

            $root.SetAttribute('name', 'JiraPS Integration Tests')
            $root.SetAttribute('total', ($totalPassed + $totalFailed + $totalSkipped).ToString())
            $root.SetAttribute('errors', '0')
            $root.SetAttribute('failures', $totalFailed.ToString())
            $root.SetAttribute('not-run', $totalSkipped.ToString())
            $root.SetAttribute('inconclusive', '0')
            $root.SetAttribute('ignored', '0')
            $root.SetAttribute('skipped', $totalSkipped.ToString())
            $root.SetAttribute('invalid', '0')
            $root.SetAttribute('date', $startTime.ToString('yyyy-MM-dd'))
            $root.SetAttribute('time', $startTime.ToString('HH:mm:ss'))

            $envElement = $mergedDoc.CreateElement('environment')
            $osName = if ($PSVersionTable.PSVersion.Major -ge 6) {
                if ($IsWindows) { 'Windows' } elseif ($IsMacOS) { 'macOS' } else { 'Linux' }
            }
            else {
                'Windows'
            }
            $envElement.SetAttribute('os-version', $osName)
            $envElement.SetAttribute('platform', "PowerShell $($PSVersionTable.PSVersion)")
            $envElement.SetAttribute('cwd', $projectRoot)
            $envElement.SetAttribute('machine-name', $env:COMPUTERNAME)
            $envElement.SetAttribute('user', $env:USERNAME)
            $root.AppendChild($envElement) | Out-Null

            $mainSuite = $mergedDoc.CreateElement('test-suite')
            $mainSuite.SetAttribute('type', 'Assembly')
            $mainSuite.SetAttribute('name', 'JiraPS.Integration.Tests')
            $mainSuite.SetAttribute('executed', 'True')
            $mainSuite.SetAttribute('result', $(if ($totalFailed -eq 0) { 'Success' } else { 'Failure' }))
            $mainSuite.SetAttribute('success', $(if ($totalFailed -eq 0) { 'True' } else { 'False' }))
            $mainSuite.SetAttribute('time', $totalDuration.TotalSeconds.ToString('0.000'))
            $mainSuite.SetAttribute('asserts', '0')

            $mainResults = $mergedDoc.CreateElement('results')
            $mainSuite.AppendChild($mainResults) | Out-Null

            foreach ($xmlFile in $xmlFiles) {
                try {
                    $fileDoc = [xml](Get-Content $xmlFile.FullName -Raw)
                    $testSuites = $fileDoc.SelectNodes('//test-suite[@type="TestFixture" or @type="Describe"]')
                    foreach ($suite in $testSuites) {
                        $importedSuite = $mergedDoc.ImportNode($suite, $true)
                        $mainResults.AppendChild($importedSuite) | Out-Null
                    }
                }
                catch {
                    Write-Warning "Failed to merge XML from $($xmlFile.Name): $_"
                }
            }

            $root.AppendChild($mainSuite) | Out-Null

            $mergedDoc.Save($OutputPath)
            Write-Host "Test results written to: $OutputPath" -ForegroundColor Cyan
        }
    }

    if ($PSCmdlet.ShouldProcess($tempResultsDir, "Remove temporary results directory")) {
        Remove-Item -Path $tempResultsDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($totalFailed -gt 0) {
    exit 1
}
else {
    exit 0
}
