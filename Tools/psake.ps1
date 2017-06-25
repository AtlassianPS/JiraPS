# PSake makes variables declared here available in other scriptblocks
Properties {
    # This refers to the root of the project directory
    $ProjectRoot = $env:APPVEYOR_BUILD_FOLDER

    # This is the root of the module folder inside the project
    $ModuleRoot = Join-Path -Path $ProjectRoot -ChildPath 'JiraPS'

    $Commit = $env:APPVEYOR_REPO_COMMIT
    $CommitMessage = $env:APPVEYOR_REPO_COMMIT_MESSAGE
    $CommitMessageExtended = $env:APPVEYOR_REPO_COMMIT_MESSAGE_EXTENDED

    # AppVeyor job ID, used to upload test results
    $JobId = $env:APPVEYOR_JOB_ID

    $Timestamp = Get-date -uformat "%Y%m%d-%H%M%S"
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestResults_PS$PSVersion`_$TimeStamp.xml"

    $line = ('-' * 60)
}

Task Init {
    $line
    Set-Location $ProjectRoot
    "Importing module"
    Import-Module "$ProjectRoot\JiraPS\JiraPS.psd1"
    "`n"
}

Task Test -Depends Init  {
    $line
    "`n`tTesting with PowerShell $PSVersion"

    # Gather test results. Store them in a variable and file
    $TestResults = Invoke-Pester -Path $ProjectRoot -PassThru -OutputFormat NUnitXml -OutputFile "$ProjectRoot\$TestFile"

    $url = "https://ci.appveyor.com/api/testresults/nunit/$($JobId)"
    "Uploading test results back to AppVeyor, url=[$url]"
    $wc = New-Object -TypeName System.Net.WebClient
    $wc.UploadFile($url, "$ProjectRoot\$TestFile")
    $wc.Dispose()

    # Remove the test file. We don't want to accidentally package it up
    Remove-Item "$ProjectRoot\$TestFile" -Force -ErrorAction SilentlyContinue

    # We don't want PSake or AppVeyor to think the build succeeded if Pester failed some tests.
    $failedCount = ($TestResults.FailedCount | Measure-Object -Sum).Sum
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
        Write-Error "$failedCount tests failed during build process."
    }
}

Task Build -Depends Test {
    $line
}

Task Deploy -Depends Build {
    # Credit to Trevor Sullivan:
    # https://github.com/pcgeek86/PSNuGet/blob/master/deploy.ps1
    function Update-ModuleManifest {
        [CmdletBinding()]
        param(
            [String] $Path,
            [String] $BuildNumber
        )

        if ([String]::IsNullOrEmpty($Path))
        {
            $Path = Get-ChildItem -Path $env:APPVEYOR_BUILD_FOLDER -Include *.psd1
            if (!$Path)
            {
                throw 'Could not find a module manifest file'
            }
        }

        $ManifestContent = Get-Content -Path $Path -Raw
        $ManifestContent = $ManifestContent -replace '(?<=ModuleVersion\s+=\s+'')(?<ModuleVersion>.*)(?='')', ('${{ModuleVersion}}.{0}' -f $BuildNumber)
        Set-Content -Path $Path -Value $ManifestContent

        $ManifestContent -match '(?<=ModuleVersion\s+=\s+'')(?<ModuleVersion>.*)(?='')' | Out-Null
        Write-Host 'Module Version patched: ' -ForegroundColor Cyan -NoNewline
        Write-Host $Matches.ModuleVersion -ForegroundColor Green
    }

    ########################################################
    $line

    if ($env:APPVEYOR_REPO_BRANCH -eq 'master' -and -not $env:APPVEYOR_PULL_REQUEST_NUMBER) {
        "Patching module manifest version with build number ($env:APPVEYOR_BUILD_NUMBER)"
        Update-ModuleManifest -Path (Join-Path -Path $ModuleRoot -ChildPath 'JiraPS.psd1') -BuildNumber $env:APPVEYOR_BUILD_NUMBER

        $publishParams = @{
            Path = $ModuleRoot
            NuGetApiKey = $env:PSGalleryAPIKey
        }

        "Parameters for publishing:"
        foreach ($p in $publishParams.Keys)
        {
            if ($p -ne 'NuGetApiKey')
            {
                "${p}:`t$($publishParams.$p)"
            } else {
                "${p}:`t[Redacted]"
            }
        }

        "Publishing module to PowerShell Gallery"
        Publish-Module @publishParams

        # $Params = @{
        #     Path = $ProjectRoot
        #     Force = $true
        #     Recurse = $false # We keep psdeploy artifacts, avoid deploying those : )
        # }
        # Invoke-PSDeploy @Verbose @Params
    }
    else {
        "This commit is not to the master branch. It will not be published."
    }
}

Task Default -Depends Deploy
