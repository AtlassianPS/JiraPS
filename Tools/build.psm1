[CmdletBinding()]
param()

function Install-PSDepend {
    if (-not (Get-Module PSDepend -ListAvailable)) {
        if (Get-Module PowershellGet -ListAvailable) {
            Install-Module PSDepend -Scope CurrentUser -ErrorAction Stop -Verbose
        }
        else {
            throw "The PowershellGet module is not available."
        }
    }
}

function Get-AppVeyorBuild {
    param()

    if (-not ($env:APPVEYOR_API_TOKEN)) {
        throw "missing api token for AppVeyor."
    }
    if (-not ($env:APPVEYOR_ACCOUNT_NAME)) {
        throw "not an appveyor build."
    }

    Invoke-RestMethod -Uri "https://ci.appveyor.com/api/projects/$env:APPVEYOR_ACCOUNT_NAME/$env:APPVEYOR_PROJECT_SLUG" -Method GET -Headers @{
        "Authorization" = "Bearer $env:APPVEYOR_API_TOKEN"
        "Content-type"  = "application/json"
    }
}

function Get-TravisBuild {
    param()

    if (-not ($env:TRAVIS_API_TOKEN)) {
        throw "missing api token for Travis-CI."
    }
    if (-not ($env:APPVEYOR_ACCOUNT_NAME)) {
        throw "not an appveyor build."
    }

    Invoke-RestMethod -Uri "https://api.travis-ci.org/builds?limit=10" -Method Get -Headers @{
        "Authorization"      = "token $env:TRAVIS_API_TOKEN"
        "Travis-API-Version" = "3"
    }
}

function allJobsFinished {
    param()
    $buildData = Get-AppVeyorBuild
    $lastJob = ($buildData.build.jobs | Select-Object -Last 1).jobId

    if ($lastJob -ne $env:APPVEYOR_JOB_ID) {
        return $false
    }

    Write-Host "[IDLE] :: waiting for other jobs to complete"

    [datetime]$stop = ([datetime]::Now).AddMinutes($env:TimeOutMins)

    do {
        $project = Get-AppVeyorBuild
        $continue = @()
        $project.build.jobs | Where-Object {$_.jobId -ne $env:APPVEYOR_JOB_ID} | Foreach-Object {
            $job = $_
            switch -regex ($job.status) {
                "failed" { throw "AppVeyor's Job ($($job.jobId)) failed." }
                "(running|success)" { $continue += $true; continue }
                Default { $continue += $false; Write-Host "new state: $_.status" }
            }
        }
        if ($false -notin $continue) { return $true }
        Start-sleep 5
    } while (([datetime]::Now) -lt $stop)

    throw "Test jobs were not finished in $env:TimeOutMins minutes"
}
