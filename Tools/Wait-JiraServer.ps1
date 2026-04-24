#requires -version 5.1

<#
.SYNOPSIS
    Polls a local Jira Data Center container until it is reachable, then provisions a regular (non-admin) test user.

.DESCRIPTION
    Used by the Server-track integration tests (.github/workflows/jira_server_ci.yml and the
    StartJiraDocker build task) to bring up Atlassian Jira inside the addono/jira-software-standalone
    Docker container and seed the user account that JIRA-side tests authenticate as.

    The script:

    1. Polls "${CI_JIRA_URL}/rest/api/2/serverInfo" every 10 seconds for up to 15 minutes,
       waiting for Jira's web app to start serving requests.
    2. Once reachable, POSTs to "/rest/api/2/user" with admin Basic auth to create a normal
       user account. If the user already exists, the call is treated as success (idempotent).

    AGENTS.md mandates that all HTTP traffic from the module flow through Invoke-JiraMethod.
    This script is the documented exception: it runs *before* the JiraPS module is imported
    (the module is not yet usable because Jira itself is not yet reachable), and it provisions
    fixtures the integration test suite then exercises through the module. Treat this file as
    test infrastructure, not module code.

.PARAMETER Url
    The Jira Data Center base URL. Defaults to $env:CI_JIRA_URL or http://localhost:2990/jira.

.PARAMETER AdminUser
    The Jira admin username used for user provisioning. Defaults to $env:CI_JIRA_ADMIN or 'admin'.

.PARAMETER AdminPassword
    The Jira admin password used for user provisioning. Defaults to $env:CI_JIRA_ADMIN_PASSWORD or 'admin'.

.PARAMETER NormalUser
    The username of the regular test user to provision. Defaults to $env:CI_JIRA_USER or 'jira_user'.

.PARAMETER NormalPassword
    The password for the regular test user. Defaults to $env:CI_JIRA_USER_PASSWORD or 'jira'.

.PARAMETER TimeoutSeconds
    The total wait budget before giving up. Defaults to 900 (15 minutes), which matches the
    healthcheck start-up grace plus several retry attempts on a cold container start.

.PARAMETER PollIntervalSeconds
    The delay between health probes. Defaults to 10.

.EXAMPLE
    pwsh ./Tools/Wait-JiraServer.ps1

.EXAMPLE
    pwsh ./Tools/Wait-JiraServer.ps1 -Url http://localhost:2990/jira -TimeoutSeconds 900

.NOTES
    Exits 0 on success, non-zero on timeout or unrecoverable provisioning error.

    Designed to run on Ubuntu PowerShell 7+ inside CI but stays PS 5.1-compatible so it can
    also be invoked from Windows desktops while iterating locally.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Test infrastructure: provisions a known-secret test user against a local Docker container, not a real instance')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'Defaults match the addono/jira-software-standalone image used in CI; never used against a real instance')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeRestMethod', '', Justification = 'Test infrastructure runs before the JiraPS module is loaded; AGENTS.md documents this as the one allowed Invoke-RestMethod site')]
[CmdletBinding()]
param(
    [Parameter()]
    [string]$Url = $(if ($env:CI_JIRA_URL) { $env:CI_JIRA_URL } else { 'http://localhost:2990/jira' }),

    [Parameter()]
    [string]$AdminUser = $(if ($env:CI_JIRA_ADMIN) { $env:CI_JIRA_ADMIN } else { 'admin' }),

    [Parameter()]
    [string]$AdminPassword = $(if ($env:CI_JIRA_ADMIN_PASSWORD) { $env:CI_JIRA_ADMIN_PASSWORD } else { 'admin' }),

    [Parameter()]
    [string]$NormalUser = $(if ($env:CI_JIRA_USER) { $env:CI_JIRA_USER } else { 'jira_user' }),

    [Parameter()]
    [string]$NormalPassword = $(if ($env:CI_JIRA_USER_PASSWORD) { $env:CI_JIRA_USER_PASSWORD } else { 'jira' }),

    [Parameter()]
    [int]$TimeoutSeconds = 900,

    [Parameter()]
    [int]$PollIntervalSeconds = 10
)

$ErrorActionPreference = 'Stop'

$baseUrl = $Url.TrimEnd('/')
$serverInfoUrl = "$baseUrl/rest/api/2/serverInfo"
$userApiUrl = "$baseUrl/rest/api/2/user"

Write-Host "==> Waiting for Jira at $serverInfoUrl (timeout: ${TimeoutSeconds}s, poll: ${PollIntervalSeconds}s)"

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$attempt = 0
$ready = $false

while ((Get-Date) -lt $deadline) {
    $attempt++
    try {
        # Documented exception to AGENTS.md (no Invoke-JiraMethod): the module is not yet
        # importable and the goal is to detect when Jira itself starts responding.
        $info = Invoke-RestMethod -Uri $serverInfoUrl -Method Get -TimeoutSec 10
        if ($info -and $info.version) {
            Write-Host ("==> Jira is up: version={0} buildNumber={1} deploymentType={2}" -f $info.version, $info.buildNumber, $info.deploymentType)
            $ready = $true
            break
        }
    }
    catch {
        $remaining = [int]([Math]::Max(0, ($deadline - (Get-Date)).TotalSeconds))
        Write-Host ("    attempt {0}: not ready yet ({1}); {2}s remaining" -f $attempt, $_.Exception.Message, $remaining)
    }

    Start-Sleep -Seconds $PollIntervalSeconds
}

if (-not $ready) {
    Write-Error "Jira did not become reachable within ${TimeoutSeconds} seconds at $serverInfoUrl."
    exit 1
}

Write-Host "==> Provisioning normal test user '$NormalUser' via $userApiUrl"

$pair = "${AdminUser}:${AdminPassword}"
$encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$headers = @{
    Authorization = "Basic $encoded"
    'X-Atlassian-Token' = 'no-check'
}

$body = @{
    name         = $NormalUser
    emailAddress = "$NormalUser@example.com"
    displayName  = 'JiraPS Integration Test User'
    password     = $NormalPassword
} | ConvertTo-Json -Compress

try {
    # Same documented exception as above: this is provisioning, not module behaviour.
    $created = Invoke-RestMethod -Uri $userApiUrl -Method Post -Headers $headers -ContentType 'application/json' -Body $body -TimeoutSec 30
    Write-Host ("==> Provisioned user: name={0} key={1}" -f $created.name, $created.key)
}
catch {
    $statusCode = $null
    if ($_.Exception.Response) {
        try { $statusCode = [int]$_.Exception.Response.StatusCode } catch { $statusCode = $null }
    }

    $message = $_.Exception.Message
    $bodyText = $null
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
        $bodyText = $_.ErrorDetails.Message
    }

    $alreadyExists = $false
    if ($statusCode -in 400, 409) {
        if ($bodyText -and ($bodyText -match 'already exists' -or $bodyText -match 'username' -or $bodyText -match 'user with that')) {
            $alreadyExists = $true
        }
        elseif ($message -match 'already exists') {
            $alreadyExists = $true
        }
    }

    if ($alreadyExists) {
        Write-Host "==> User '$NormalUser' already exists; treating as success."
    }
    else {
        Write-Error "Failed to provision normal user '$NormalUser' (status=$statusCode): $message`n$bodyText"
        exit 2
    }
}

Write-Host "==> Jira is ready and the test user is provisioned."
exit 0
