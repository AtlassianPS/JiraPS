Write-Host "Starting Pre-Commit Hooks..." -ForegroundColor Cyan
try {
    Write-Host "PSScriptRoot: $PSScriptRoot"
    $moduleManifest = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'PSJira\PSJira.psd1'
    Write-Host "Module manifest file: $moduleManifest"
    Import-Module $moduleManifest
    $pesterResults = Invoke-Pester -Quiet -PassThru
    if ($pesterResults.FailedCount -gt 0)
    {
        Write-Error "Pester failed $($pesterResults.FailedCount) tests."
        Write-Host
        Write-Host "Summary of failed tests:" -ForegroundColor White -BackgroundColor DarkRed
        Write-Host "------------------------" -ForegroundColor White -BackgroundColor DarkRed

        $failedTests = $pesterResults.TestResult | Where-Object -FilterScript {$_.Passed -ne $true}
        $failedTests | ForEach-Object {
            $test = $_
            [PSCustomObject] @{
                Describe = $test.Describe
                Context = $test.Context
                Name = "It `"$($test.Name)`""
                Result = $test.Result
                Message = $test.FailureMessage
            }
        } | Sort-Object -Property Describe,Context,Name,Result,FailureMessage | Format-List

        exit 1
    } else {
        Write-Host "All Pester tests passed." -ForegroundColor Green
        exit 0
    }
}
catch {
    $err = $_
    Write-Error -Message $_
    exit 1
}