[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Cloud', 'Server')]
    [string] $Track,

    [string] $ResultPath = 'Test-Integration.xml',

    [string] $RequiredSuitesPath = "$PSScriptRoot/../Tests/Integration/RequiredSuites.psd1"
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ResultPath -PathType Leaf)) {
    throw "${Track}: Integration result file '$ResultPath' is missing. Required suites were not verified."
}

try {
    [xml] $report = Get-Content -LiteralPath $ResultPath -Raw
}
catch {
    throw "${Track}: Cannot read NUnit integration results from '$ResultPath': $_"
}

$requirements = Import-PowerShellDataFile -LiteralPath $RequiredSuitesPath
if (-not $requirements.Suites) {
    throw "${Track}: No required integration suites configured in '$RequiredSuitesPath'."
}

$otherTrack = if ($Track -eq 'Cloud') { 'Server' } else { 'Cloud' }
$problems = @()

foreach ($requirement in $requirements.Suites) {
    $file = $requirement.File
    $requiredTests = @($requirement.Common) + @($requirement[$Track])
    if (-not $file -or $requiredTests.Count -eq 0) {
        throw "${Track}: Each required suite must specify a File and required tests."
    }

    # The parallel runner also copies nested fixtures; use the direct file fixture once.
    $fixtures = @($report.SelectNodes('/test-results/test-suite/results/test-suite') | Where-Object {
            ($_.GetAttribute('name') -replace '\\', '/').Split('/')[-1] -ceq $file
        })
    if ($fixtures.Count -ne 1) {
        $problems += "${file}: expected one file fixture, found $($fixtures.Count)."
        continue
    }

    $tests = @($fixtures[0].SelectNodes('.//test-case'))
    foreach ($name in $requiredTests) {
        $foundTests = @($tests | Where-Object { $_.GetAttribute('name') -ceq $name })
        if ($foundTests.Count -ne 1) {
            $problems += "${file}: required test '$name' is absent or duplicated (found $($foundTests.Count))."
        }
    }

    $allowedSkips = @($requirement[$otherTrack] | Where-Object { $_ -cnotin $requiredTests })
    foreach ($test in $tests) {
        $name = $test.GetAttribute('name')
        $result = $test.GetAttribute('result')
        $executed = $test.GetAttribute('executed')
        if ($result -eq 'Success' -and $executed -eq 'True') {
            continue
        }
        if ($name -cin $allowedSkips -and $result -eq 'Ignored' -and $executed -eq 'False') {
            continue
        }
        $problems += "${file}: test '$name' did not pass (result='$result', executed='$executed')."
    }
}

if ($problems.Count -gt 0) {
    throw "${Track}: Required integration coverage failed:`n - $($problems -join "`n - ")"
}

Write-Output "${Track}: Required integration coverage verified for $(@($requirements.Suites).Count) suite(s)."
