# requires -module InvokeBuild
[CmdletBinding()]
param()

function Assert-True {
    param(
        [ScriptBlock]$ScriptBlock,
        [String]$Message
    )

    if (-not $ScriptBlock) {
        throw $Message
    }
}

function Add-ToModulePath ([String]$Path) {
    $PSModulePath = $env:PSModulePath -split ([IO.Path]::PathSeparator)
    if ($Path -notin $PSModulePath) {
        $PSModulePath += $Path
        $env:PSModulePath = $PSModulePath -join ([IO.Path]::PathSeparator)
    }
}
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

    Assert-True { $env:APPVEYOR_API_TOKEN } "missing api token for AppVeyor."
    Assert-True { $env:APPVEYOR_ACCOUNT_NAME } "not an appveyor build."

    Invoke-RestMethod -Uri "https://ci.appveyor.com/api/projects/$env:APPVEYOR_ACCOUNT_NAME/$env:APPVEYOR_PROJECT_SLUG" -Method GET -Headers @{
        "Authorization" = "Bearer $env:APPVEYOR_API_TOKEN"
        "Content-type"  = "application/json"
    }
}

function Get-TravisBuild {
    param()

    Assert-True { $env:TRAVIS_API_TOKEN } "missing api token for Travis-CI."
    Assert-True { $env:APPVEYOR_ACCOUNT_NAME } "not an appveyor build."

    Invoke-RestMethod -Uri "https://api.travis-ci.org/builds?limit=10" -Method Get -Headers @{
        "Authorization"      = "token $env:TRAVIS_API_TOKEN"
        "Travis-API-Version" = "3"
    }
}

function Test-IsLastJob {
    param()

    if (-not ('AppVeyor' -eq $env:BHBuildSystem)) {
        return $true
    }
    Assert-True { $env:APPVEYOR_JOB_ID } "Invalid Job identifier"

    $buildData = Get-AppVeyorBuild
    $lastJob = ($buildData.build.jobs | Select-Object -Last 1).jobId

    if ($lastJob -eq $env:APPVEYOR_JOB_ID) {
        return $true
    }
    else {
        return $false
    }
}

function Test-ShouldDeploy {
    # only deploy master branch
    if (-not ('master' -eq $env:BHBranchName)) {
        return $false
    }
    # it cannot be a PR
    if ($env:APPVEYOR_PULL_REQUEST_NUMBER) {
        return $false
    }
    # only deploy from AppVeyor
    if (-not ('AppVeyor' -eq $env:BHBuildSystem)) {
        return $false
    }
    # must be last job of AppVeyor
    if (-not (Test-IsLastJob)) {
        return $false
    }
    # Travis-CI must be finished (if used)
    # TODO: (Test-TravisProgress) -and
    # it cannot have a commit message that contains "skip-deploy"
    if ($env:BHCommitMessage -like '*skip-deploy*') {
        return $false
    }

    return $true
}

function Publish-GithubRelease {
    param(
        [String]$ReleaseText,
        [Object]$NextBuildVersion
    )

    Assert-True { $env:access_token } "Missing Github authentication"
    Assert-True { $env:APPVEYOR_REPO_NAME } "Missing AppVeyor's Repo Name"

    $body = @{
        "tag_name"         = "v$NextBuildVersion"
        "target_commitish" = "master"
        "name"             = "v$NextBuildVersion"
        "body"             = $ReleaseText
        "draft"            = $false
        "prerelease"       = $false
    } | ConvertTo-Json

    $releaseParams = @{
        Uri         = "https://api.github.com/repos/{0}/releases" -f $env:APPVEYOR_REPO_NAME
        Method      = 'POST'
        Headers     = @{
            Authorization = 'Basic ' + [Convert]::ToBase64String(
                [Text.Encoding]::ASCII.GetBytes($env:access_token + ":x-oauth-basic")
            )
        }
        ContentType = 'application/json'
        Body        = $body
        ErrorAction = "Stop"
    }
    Invoke-RestMethod @releaseParams
}

function Publish-GithubReleaseArtifact {
    param(
        [Uri]$Uri,
        [String]$Path
    )

    Assert-True { $env:access_token } "Missing Github authentication"
    Assert-True { $env:APPVEYOR_REPO_NAME } "Missing AppVeyor's Repo Name"

    $body = [System.IO.File]::ReadAllBytes($Path)
    $assetParams = @{
        Uri         = $Uri
        Method      = 'POST'
        Headers     = @{
            Authorization = 'Basic ' + [Convert]::ToBase64String(
                [Text.Encoding]::ASCII.GetBytes($env:access_token + ":x-oauth-basic")
            )
        }
        ContentType = "application/zip"
        Body        = $body
    }
    Invoke-RestMethod @assetParams
}

#region Old
# function allJobsFinished {
#     param()

#     if (-not ('AppVeyor' -eq $env:BHBuildSystem)) {
#         return $true
#     }
#     if (-not ($env:APPVEYOR_API_TOKEN)) {
#         Write-Warning "Missing `$env:APPVEYOR_API_TOKEN"
#         return $true
#     }
#     if (-not ($env:APPVEYOR_ACCOUNT_NAME)) {
#         Write-Warning "Missing `$env:APPVEYOR_ACCOUNT_NAME"
#         return $true
#     }

#     Test-IsLastJob

#     Write-Host "[IDLE] :: waiting for other jobs to complete"

#     [datetime]$stop = ([datetime]::Now).AddMinutes($env:TimeOutMins)

#     do {
#         $project = Get-AppVeyorBuild
#         $continue = @()
#         $project.build.jobs | Where-Object {$_.jobId -ne $env:APPVEYOR_JOB_ID} | Foreach-Object {
#             $job = $_
#             switch -regex ($job.status) {
#                 "failed" { throw "AppVeyor's Job ($($job.jobId)) failed." }
#                 "(running|success)" { $continue += $true; continue }
#                 Default { $continue += $false; Write-Host "new state: $_.status" }
#             }
#         }
#         if ($false -notin $continue) { return $true }
#         Start-sleep 5
#     } while (([datetime]::Now) -lt $stop)

#     throw "Test jobs were not finished in $env:TimeOutMins minutes"
# }
#endregion Old
