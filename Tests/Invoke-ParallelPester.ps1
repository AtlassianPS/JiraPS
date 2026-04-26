<#
.SYNOPSIS
    Runs Pester integration tests in parallel (PS7+) or sequentially (PS5.1).

.DESCRIPTION
    This script runs multiple Pester test files to support integration testing.
    On PowerShell 7+, files run concurrently as Start-ThreadJob jobs (one job per
    test file, throttled by -ThrottleLimit). On PowerShell 5.1, files run
    sequentially as a fallback.

    Each test file generates its own NUnit XML which is then merged into a single
    output file with full test-case details (names, durations, failure messages).

    NOTE: This script provides file-level parallelization. Pester 5's built-in
    -Parallel flag provides test-level parallelization within a single invocation.
    The file-level approach is used here for isolation between integration test
    files that may have conflicting global state or authentication sessions.

    Why Start-ThreadJob and not ForEach-Object -Parallel: ForEach-Object -Parallel
    cannot time-bound its wait for a child runspace to fully Close, so a single
    runspace that holds non-foreground threads alive (e.g. .NET HttpClient
    keep-alive connections from Invoke-WebRequest) can hang the whole orchestrator
    long after the per-file Pester runs all completed — observed at ~53 min in
    CI run #24937590588 before the GitHub Actions step timeout finally killed it.
    Start-ThreadJob lets us Wait-Job -Timeout each file individually, Stop-Job +
    Remove-Job -Force to tear down stuck runspaces deterministically, and proceed
    to the merged-XML write block + a clean `exit` regardless of background
    thread state.

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

$results = @()
$generateXml = [bool]$OutputPath

# Define the test execution body once as text. Both branches (parallel via
# ForEach-Object -Parallel, and sequential via direct invocation) materialize
# it into a script block and run it. Keeping it as text means we have a single
# source of truth for how a test file is executed.
$helpersPath = Join-Path $PSScriptRoot 'Helpers/IntegrationTestTools.ps1'

$runTestBodyText = @'
param($testFile, $projectRoot, $tagFilter, $excludeTagFilter, $outputVerbosity, $tempResultsDir, $generateXml, $helpersPath)

try {
    if (Test-Path $helpersPath) {
        . $helpersPath
        Read-DotEnvFile -Path (Join-Path $projectRoot '.env')
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
'@

if ($canParallel) {
    # Why Start-ThreadJob and not ForEach-Object -Parallel:
    # CI run #24937590588 reproduced the same orchestrator hang seen in
    # #24935398326 — every per-file Pester run completed and emitted its
    # result object, but then `ForEach-Object -Parallel` blocked indefinitely
    # while trying to mark the child runspaces as completed. The job-level
    # `timeout-minutes: 25` on the `server_integration_tests` job's "Run full
    # Server-tagged integration suite" step in integration_tests.yml is
    # what eventually killed it.
    #
    # Root cause: integration tests call Invoke-WebRequest / New-JiraSession,
    # which drives .NET's HttpClient → keeps idle TCP connections + their
    # background ThreadPool continuations alive after the user code returns.
    # PowerShell 7's ForEach-Object -Parallel waits for the runspace to be
    # fully Closed (not just for the script block to finish) before exiting,
    # and there is no public knob to time-bound that wait. So when even one
    # runspace's background HTTP thread won't wind down, the whole pipeline
    # stalls — for ~53 min in the observed run before GitHub's job timeout
    # finally cancelled the step.
    #
    # Start-ThreadJob gives us explicit per-job control:
    #   * Wait-Job -Timeout returns even if the runspace is still spinning,
    #     so a single hung file can't take down the whole suite.
    #   * Stop-Job + Remove-Job -Force tears down the runspace deterministically.
    #   * -ThrottleLimit still bounds concurrency the same way as FE-O-P.
    #   * -StreamingHost preserves the live Write-Host streaming we get from
    #     FE-O-P today, so CI logs stay informative as files complete.
    # When this script's final `exit` runs, any still-running background
    # threads are reaped by the process tearing down — they are no longer
    # the orchestrator's problem to drain cleanly.
    #
    # Per-file budget: 600s (10 min) is ~3x the slowest observed per-file
    # duration (the broader CRUD suites land at ~3 min wall-clock against
    # the AMPS H2 backend during heavily-parallel runs). A file that exceeds
    # that is reported as a synthetic "Orchestrator timeout" failure rather
    # than blocking the rest of the suite — the merged XML still gets the
    # results from every file that did finish.
    $perFileTimeoutSeconds = 600
    $jobInfos = New-Object System.Collections.Generic.List[object]
    foreach ($testFile in $testFiles) {
        # NOTE: -StreamingHost streams Write-Host / Write-Information from
        # the child runspace to the parent's host as it is produced, which
        # keeps CI logs in the same shape FE-O-P produced. We pass $Host
        # explicitly because $PSHost in a ThreadJob defaults to a default
        # PSHost that does not write to the Actions runner stdout.
        $job = Start-ThreadJob `
            -ScriptBlock ([scriptblock]::Create($runTestBodyText)) `
            -ArgumentList @($testFile, $projectRoot, $Tag, $ExcludeTag, $Output, $tempResultsDir, $generateXml, $helpersPath) `
            -ThrottleLimit $ThrottleLimit `
            -StreamingHost $Host `
            -Name "Pester:$($testFile.BaseName)"
        $jobInfos.Add(@{ File = $testFile; Job = $job })
    }

    foreach ($info in $jobInfos) {
        $job = $info.Job
        $file = $info.File

        # Wait-Job with -Timeout returns the job if it finished, $null if
        # the timeout elapsed first. This is the timeout that protects
        # against the FE-O-P-style runspace-cleanup hang on a per-file basis.
        $finished = Wait-Job -Job $job -Timeout $perFileTimeoutSeconds

        if (-not $finished) {
            Write-Warning "Test file [$($file.Name)] exceeded ${perFileTimeoutSeconds}s budget; stopping the runspace and recording an orchestrator timeout."
            try { Stop-Job -Job $job -ErrorAction SilentlyContinue } catch { Write-Warning "Stop-Job [$($job.Name)] threw: $_" }
            $results += [PSCustomObject]@{
                File        = $file.Name
                Passed      = 0
                Failed      = 1
                Skipped     = 0
                Duration    = [TimeSpan]::FromSeconds($perFileTimeoutSeconds)
                Success     = $false
                Error       = "Per-file orchestrator timeout (${perFileTimeoutSeconds}s) — runspace stopped, see Wait-Job timeout warning above."
                FailedTests = @([PSCustomObject]@{
                        Name         = 'Orchestrator timeout'
                        ErrorMessage = "Test file [$($file.Name)] did not produce a Pester result object within ${perFileTimeoutSeconds}s. The runspace was force-stopped to keep the rest of the suite running."
                    })
                XmlPath     = $null
            }
        }
        else {
            try {
                # Redirect the Information stream (6>) to $null. The child
                # already wrote everything to the parent's host live via
                # -StreamingHost above; without this redirect Receive-Job
                # re-emits the Information records and we get every Pester
                # line printed twice (once streamed, once replayed) — see
                # the duplicated "Starting discovery / Discovery found / Running
                # tests / [+] file / Tests completed / Tests Passed" blocks
                # that appear in a smoke test against two unit test files.
                # Keeping Error (2>), Warning (3>), Verbose (4>), and Debug
                # (5>) intact: those are not streamed by -StreamingHost and
                # we do want them surfaced if Receive-Job hits a real problem.
                $jobOutput = Receive-Job -Job $job -ErrorAction Stop 6> $null
                if ($null -ne $jobOutput) { $results += $jobOutput }
            }
            catch {
                Write-Warning "Receive-Job [$($job.Name)] threw: $_"
                $results += [PSCustomObject]@{
                    File        = $file.Name
                    Passed      = 0
                    Failed      = 1
                    Skipped     = 0
                    Duration    = [TimeSpan]::Zero
                    Success     = $false
                    Error       = "Receive-Job failed: $_"
                    FailedTests = @([PSCustomObject]@{ Name = 'Receive-Job failure'; ErrorMessage = $_.Exception.Message })
                    XmlPath     = $null
                }
            }
        }

        # Force-remove releases the runspace even if Stop-Job above didn't
        # fully tear down a hung HTTP background thread. We don't care if
        # this throws — any thread that survives here will be reaped when
        # the script `exit`s below.
        try { Remove-Job -Job $job -Force -ErrorAction SilentlyContinue } catch { Write-Warning "Remove-Job [$($job.Name)] threw: $_" }
    }
}
else {
    $runTestFile = [scriptblock]::Create($runTestBodyText)
    foreach ($testFile in $testFiles) {
        $results += & $runTestFile $testFile $projectRoot $Tag $ExcludeTag $Output $tempResultsDir $generateXml $helpersPath
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
            $envElement.SetAttribute('machine-name', [Environment]::MachineName)
            $envElement.SetAttribute('user', [Environment]::UserName)
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
