# This approach shamelessly copied from RamblingCookieMonster. ^.^

# Be SURE to install Pester using appveyor.yml. Chocolatey is available, so the simplest way is to use this:
# cinst -y Pester

#region Variables
# AppVeyor environment variables

# This refers to the root of the project directory
$ProjectRoot = $env:APPVEYOR_BUILD_FOLDER

# This is the root of the module folder inside the project
$ModuleRoot = Join-Path -Path $ProjectRoot -ChildPath 'PSJira'

# This is AppVeyor's internal job ID, used to return results using their REST API
$JobId = $env:APPVEYOR_JOB_ID
#endregion

#region Init

Write-Host "Initializing AppVeyor tests." -ForegroundColor Cyan
# AppVeyor environment variable set when running in an AppVeyor environment.
if ($env:CI -ne $true)
{
    throw "This script does not appear to be running in an AppVeyor environment."
}

Write-Host "AppVeyor tests initialized (Job ID $JobId)" -ForegroundColor Cyan

# PSJira requires PS3.0 or greater, but I don't like to rely on module auto-loading.
Import-Module Pester

# We'll also need to import this module, since AppVeyor won't put it in $PSModulePath.
Import-Module -Name "$ModuleRoot\PSJira.psm1"

Push-Location -Path $ModuleRoot
$resultsFile = Join-Path -Path $ProjectRoot -ChildPath 'TestResults.xml'
#endregion

# Run the tests
Write-Host "Invoking Pester tests" -ForegroundColor Cyan
$pesterResults = Invoke-Pester -OutputFormat NUnitXml -OutputFile $resultsFile -PassThru

# Upload test results back to AppVeyor
# http://www.appveyor.com/docs/running-tests#uploading-xml-test-results

$url = "https://ci.appveyor.com/api/testresults/nunit/$($JobId)"
Write-Host "Uploading test results back to AppVeyor, url=[$url]" -ForegroundColor Cyan
$wc = New-Object -TypeName System.Net.WebClient
$wc.UploadFile($url, $resultsFile)
$wc.Dispose()

# We don't want AppVeyor to think the build succeeded if Pester failed some tests.
$failedCount = ($pesterResults.FailedCount | Measure-Object -Sum).Sum
if ($failedCount -gt 0)
{
    Write-Host "Creating Pester failed test summary" -ForegroundColor Cyan

    # Display a summary of the tests that failed in the console.

    # We break some of the PowerShell rules here by using Format-List in a script,
    # but since this is a specialized script designed to write text to a screen, it's
    # okay in this instance. Detailed information is already passed to AppVeyor in the
    # NUnit XML file that we uploaded.

    Write-Host
    Write-Host "Summary of failed tests:" -ForegroundColor White -BackgroundColor DarkRed
    Write-Host "------------------------" -ForegroundColor White -BackgroundColor DarkRed

    $failedTests = $pesterResults.TestResult | Where-Object -FilterScript {$_.Passed -ne $true}
    $failedTests | ForEach-Object {
        $test = $_
        [PSCustomObject] @{
            Describe = $Test.Describe;
            Context = $Test.Context;
            Name = "It `"$($test.Name)`"";
            Result = $test.Result;
        }
    } | Sort-Object -Property Describe,Context,Name,Result | Format-List

    # Generate a terminating exception so AppVeyor understands that the build did not succeed
    throw "$failedCount tests failed during build process."
}

Pop-Location
