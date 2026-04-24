#requires -version 5.1

<#
.SYNOPSIS
    Polls a local Jira Data Center container until it is reachable, then provisions a regular (non-admin) test user.

.DESCRIPTION
    Used by the Server-track integration tests (.github/workflows/jira_server_ci.yml and the
    StartJiraDocker build task) to bring up Atlassian Jira inside the moveworkforward/atlas-run-standalone
    Docker container (Atlassian Plugin SDK 9.6.0 + Jira Software 11.0.1) and seed the user
    account that JIRA-side tests authenticate as.

    The script:

    1. Polls "${CI_JIRA_URL}/rest/api/2/serverInfo" every 10 seconds for up to 20 minutes,
       waiting for Jira's web app to start serving requests (cold boot includes Maven
       dep verification + Tomcat startup + jira.war extraction + first-time DB init).
       The poll is sent with admin Basic auth so it works regardless of whether the image
       allows anonymous access — the moveworkforward image, for example, returns 401 on
       /serverInfo for anonymous callers, so we have to authenticate even on the readiness
       probe.
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
    The total wait budget before giving up. Defaults to 1200 (20 minutes), which matches the
    SDK + Tomcat + Jira cold-boot budget plus several retry attempts. Cold boot of the
    moveworkforward image typically completes in 5-10 minutes on a GitHub Actions runner.

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
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'Defaults match the moveworkforward/atlas-run-standalone image used in CI; never used against a real instance')]
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
    [string]$ProjectKey = $(if ($env:JIRA_TEST_PROJECT) { $env:JIRA_TEST_PROJECT } else { 'TEST' }),

    [Parameter()]
    [string]$ProjectName = $(if ($env:JIRA_TEST_PROJECT_NAME) { $env:JIRA_TEST_PROJECT_NAME } else { 'JiraPS Integration Tests' }),

    [Parameter()]
    [int]$TimeoutSeconds = 1200,

    [Parameter()]
    [int]$PollIntervalSeconds = 10
)

$ErrorActionPreference = 'Stop'

$baseUrl = $Url.TrimEnd('/')
$serverInfoUrl = "$baseUrl/rest/api/2/serverInfo"
$userApiUrl = "$baseUrl/rest/api/2/user"
$projectApiUrl = "$baseUrl/rest/api/2/project"
$issueApiUrl = "$baseUrl/rest/api/2/issue"

# Build Basic auth headers up-front: needed for both the readiness probe (the
# moveworkforward image returns 401 on /serverInfo for anonymous callers, even
# once Jira is fully up) and the user-provisioning POST. Sending creds on the
# probe is harmless against installs that allow anonymous access too.
$pair = "${AdminUser}:${AdminPassword}"
$encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
$headers = @{
    Authorization = "Basic $encoded"
    'X-Atlassian-Token' = 'no-check'
}

Write-Host "==> Waiting for Jira at $serverInfoUrl (timeout: ${TimeoutSeconds}s, poll: ${PollIntervalSeconds}s)"

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$attempt = 0
$ready = $false

while ((Get-Date) -lt $deadline) {
    $attempt++
    try {
        # Documented exception to AGENTS.md (no Invoke-JiraMethod): the module is not yet
        # importable and the goal is to detect when Jira itself starts responding.
        $info = Invoke-RestMethod -Uri $serverInfoUrl -Method Get -Headers $headers -TimeoutSec 10
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

Write-Host "==> Provisioning test project '$ProjectKey' via $projectApiUrl"

# The integration test suite expects a project with key 'TEST' (override via
# JIRA_TEST_PROJECT). The moveworkforward image starts with no projects.
#
# Project creation in Jira Server/DC requires a (projectTypeKey, projectTemplateKey)
# pair that the running instance actually has installed. Templates vary across
# Jira versions and bundle combinations, so rather than hard-coding values we
# enumerate the templates the live server reports and try them in order until
# one works.
$templatesUrl = "$baseUrl/rest/project-templates/1.0/templates"
$candidatePairs = New-Object 'System.Collections.Generic.List[hashtable]'

try {
    $templatesResponse = Invoke-RestMethod -Uri $templatesUrl -Method Get -Headers $headers -TimeoutSec 30
    # Response shape: { projectTemplates: [ { projectTypeBean: { key }, projectTemplateModuleCompleteKey, ... } ], ... }
    if ($templatesResponse.projectTemplates) {
        foreach ($tpl in $templatesResponse.projectTemplates) {
            $typeKey = $null
            try { $typeKey = $tpl.projectTypeBean.key } catch { }
            $tplKey = $null
            if ($tpl.projectTemplateModuleCompleteKey) {
                $tplKey = $tpl.projectTemplateModuleCompleteKey
            } elseif ($tpl.projectTemplateModuleKey) {
                $tplKey = $tpl.projectTemplateModuleKey
            }
            if ($typeKey -and $tplKey) {
                $candidatePairs.Add(@{ ProjectTypeKey = $typeKey; ProjectTemplateKey = $tplKey })
            }
        }
        Write-Host ("==> Discovered {0} project templates from {1}" -f $candidatePairs.Count, $templatesUrl)
        foreach ($p in $candidatePairs) {
            Write-Host ("    - {0} / {1}" -f $p.ProjectTypeKey, $p.ProjectTemplateKey)
        }
    }
    else {
        Write-Host "==> Templates endpoint returned no entries; will fall through to hardcoded candidates."
    }
}
catch {
    Write-Host ("==> Could not enumerate templates from {0}: {1}. Falling back to hardcoded candidates." -f $templatesUrl, $_.Exception.Message)
}

# Always append a known-good fallback list so we still try sensible defaults if
# enumeration failed entirely or returned a sparse response.
$fallbacks = @(
    @{ ProjectTypeKey = 'software'; ProjectTemplateKey = 'com.pyxis.greenhopper.jira:gh-simplified-basic' }
    @{ ProjectTypeKey = 'software'; ProjectTemplateKey = 'com.pyxis.greenhopper.jira:gh-simplified-scrum-classic' }
    @{ ProjectTypeKey = 'software'; ProjectTemplateKey = 'com.pyxis.greenhopper.jira:gh-simplified-kanban-classic' }
    @{ ProjectTypeKey = 'software'; ProjectTemplateKey = 'com.pyxis.greenhopper.jira:gh-simplified-agility-kanban' }
    @{ ProjectTypeKey = 'business'; ProjectTemplateKey = 'com.atlassian.jira-core-project-templates:jira-core-simplified-process-control' }
    @{ ProjectTypeKey = 'business'; ProjectTemplateKey = 'com.atlassian.jira-core-project-templates:jira-core-simplified-task-tracking' }
    @{ ProjectTypeKey = 'business'; ProjectTemplateKey = 'com.atlassian.jira-core-project-templates:jira-core-simplified-project-management' }
)
foreach ($f in $fallbacks) {
    $alreadyListed = $false
    foreach ($existing in $candidatePairs) {
        if ($existing.ProjectTypeKey -eq $f.ProjectTypeKey -and $existing.ProjectTemplateKey -eq $f.ProjectTemplateKey) {
            $alreadyListed = $true
            break
        }
    }
    if (-not $alreadyListed) { $candidatePairs.Add($f) }
}

$project = $null
$lastError = $null
foreach ($pair in $candidatePairs) {
    $body = @{
        key                = $ProjectKey
        name               = $ProjectName
        projectTypeKey     = $pair.ProjectTypeKey
        projectTemplateKey = $pair.ProjectTemplateKey
        lead               = $AdminUser
        description        = 'Created by Tools/Wait-JiraServer.ps1 for JiraPS integration tests. Safe to delete.'
        assigneeType       = 'PROJECT_LEAD'
    } | ConvertTo-Json -Compress

    try {
        Write-Host ("==> Trying template: {0} / {1}" -f $pair.ProjectTypeKey, $pair.ProjectTemplateKey)
        $project = Invoke-RestMethod -Uri $projectApiUrl -Method Post -Headers $headers -ContentType 'application/json' -Body $body -TimeoutSec 60
        Write-Host ("==> Provisioned project: key={0} id={1} (type={2} template={3})" -f $project.key, $project.id, $pair.ProjectTypeKey, $pair.ProjectTemplateKey)
        break
    }
    catch {
        $statusCode = $null
        if ($_.Exception.Response) {
            try { $statusCode = [int]$_.Exception.Response.StatusCode } catch { $statusCode = $null }
        }
        $bodyText = if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $_.ErrorDetails.Message } else { $null }
        $lastError = "status=$statusCode message=$($_.Exception.Message) body=$bodyText"

        if ($statusCode -in 400, 409 -and $bodyText -and ($bodyText -match 'key.*already.*used' -or $bodyText -match 'project.*already.*exists' -or $bodyText -match 'A project with that name already exists')) {
            Write-Host "==> Project '$ProjectKey' already exists; treating as success."
            $project = [PSCustomObject]@{ key = $ProjectKey; id = $null }
            break
        }
        Write-Host ("    rejected: {0}" -f $lastError)
    }
}

if (-not $project) {
    Write-Error "Failed to provision project '$ProjectKey' with any of the $($candidatePairs.Count) candidate templates. Last error: $lastError"
    exit 3
}

Write-Host "==> Seeding baseline issue in project '$ProjectKey'"

# Create one Task so read-only tests (Get-JiraIssue, JQL search, Get-JiraComment
# fixture queries, etc.) have something to discover. Idempotency: if there's
# already an issue we don't care, this is a baseline and tests create their own.
$issueBody = @{
    fields = @{
        project   = @{ key = $ProjectKey }
        summary   = 'JiraPS-IntTest-Baseline'
        issuetype = @{ name = 'Task' }
        description = 'Baseline issue created by Tools/Wait-JiraServer.ps1. Safe to delete.'
    }
} | ConvertTo-Json -Depth 5 -Compress

try {
    $issue = Invoke-RestMethod -Uri $issueApiUrl -Method Post -Headers $headers -ContentType 'application/json' -Body $issueBody -TimeoutSec 30
    Write-Host ("==> Seeded baseline issue: key={0}" -f $issue.key)
}
catch {
    $issueStatus = $null
    if ($_.Exception.Response) {
        try { $issueStatus = [int]$_.Exception.Response.StatusCode } catch { $issueStatus = $null }
    }
    $issueBodyText = if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $_.ErrorDetails.Message } else { $null }
    # Non-fatal — most tests create their own issues. Just log and continue.
    Write-Host "==> Baseline issue creation failed (status=$issueStatus): $($_.Exception.Message)`n$issueBodyText"
    Write-Host "==> Continuing — tests that require an existing issue may skip."
}

Write-Host "==> Jira is ready, the test user is provisioned, and the test project '$ProjectKey' is available."
exit 0
