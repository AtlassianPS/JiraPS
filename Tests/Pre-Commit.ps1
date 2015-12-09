Write-Host
Write-Host "Starting Pre-Commit Hooks..." -ForegroundColor Cyan
try {
    $results = Invoke-Pester -PassThru
    if ($results.FailedCount -gt 0)
    {
        Write-Error "Pester failed $($results.FailedCount) tests."
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

        exit 1
    }
}
catch {
    $err = $_
    Write-Error -Message $_
    exit 1
}