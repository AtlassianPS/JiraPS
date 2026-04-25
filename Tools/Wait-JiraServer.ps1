#requires -version 5.1

<#
.SYNOPSIS
    Polls a local Jira Data Center container until it is reachable, then provisions the
    test user, the fixture project, and a baseline issue used by the Server-tagged
    integration suite.

.DESCRIPTION
    Used by the Server-track integration tests (.github/workflows/jira_server_ci.yml and the
    StartJiraDocker build task) to bring up Atlassian Jira inside the moveworkforward/atlas-run-standalone
    Docker container (Atlassian Plugin SDK 9.6.0 + Jira Software 11.0.1) and seed the
    fixtures the integration test suite then exercises through the JiraPS module.

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
    3. Discovers the (projectTypeKey, projectTemplateKey) pairs the running Jira advertises
       via /rest/project-templates/1.0/templates, sorts them so 'task' / 'software-development'
       templates come first (the Task issuetype the Server-tagged tests rely on), and POSTs
       to /rest/api/2/project until one of the candidates is accepted. Hardcoded canonical
       Server templates are tried as a last-resort fallback. This is necessary because the
       AMPS standalone image only registers a single 'business' projectType and rejects every
       canonical Jira Software template key.
    4. Queries /rest/api/2/issue/createmeta?projectKeys=$ProjectKey to discover an issuetype
       the just-created project actually accepts (jira-core projects don't always ship Task),
       seeds one baseline issue, and exports JIRA_TEST_PROJECT and JIRA_TEST_ISSUE to
       $env:GITHUB_ENV so downstream test steps see them.

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
    Exit codes:
      0 - Jira reachable, normal user provisioned, fixture project '$ProjectKey' provisioned,
          and (best-effort) one baseline issue seeded. JIRA_TEST_PROJECT (and JIRA_TEST_ISSUE
          when the baseline seed succeeded) are written to $env:GITHUB_ENV so the next CI
          step sees them. Tests that depend on JIRA_TEST_ISSUE self-skip when it is empty,
          so a failed baseline seed does not turn the suite red.
      1 - Jira did not become reachable inside -TimeoutSeconds.
      2 - Normal user provisioning failed and the user did not already exist.
      3 - Fixture project '$ProjectKey' could not be provisioned with any of the candidate
          (projectTypeKey, projectTemplateKey) pairs (discovered via /rest/project-templates/1.0/templates
          plus a hardcoded fallback list). This is a hard failure: downstream Server-tagged
          tests cannot run without a project.

    Designed to run on Ubuntu PowerShell 7+ inside CI but stays PS 5.1-compatible so it can
    also be invoked from Windows desktops while iterating locally.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Test infrastructure: provisions a known-secret test user against a local Docker container, not a real instance')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'Defaults match the moveworkforward/atlas-run-standalone image used in CI; never used against a real instance')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeRestMethod', '', Justification = 'Test infrastructure runs before the JiraPS module is loaded; AGENTS.md documents this as the one allowed Invoke-RestMethod site')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Diagnostic CI script: this file runs in jira_server_ci.yml and StartJiraDocker where the operator (CI logs / interactive shell) is the consumer. Write-Host is the correct primitive for prompt-style status banners ("==> ...", "    attempt N: ..."). Write-Output would pollute the script''s return value; Write-Verbose/-Information would be hidden by default in CI logs and obscure the boot/probe progress that humans actively read.')]
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
    Authorization       = "Basic $encoded"
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
# pair that the running instance has installed, plus references to existing
# permission/notification/security schemes (otherwise the create fails with an
# unhelpful 400). The pycontribs/jira tests do the same dance — see their
# `Jira.create_project()` (jira/client.py): they look up the default schemes by
# name first, then POST to /rest/api/2/project with the full payload.
#
# Hardcoded template keys do NOT work against the moveworkforward/atlas-run-standalone
# image: it ships only the bundled `business` project type, and the canonical
# template names (`com.pyxis.greenhopper.jira:basic-software-development-template`,
# `jira-core-simplified-task-tracking`, etc.) are not registered. We therefore
# query `/rest/project-templates/1.0/templates` first to discover the actual
# (projectTypeKey, projectTemplateKey) pairs the running instance advertises,
# fall back to the canonical Server pairs only if discovery returns nothing.

# 1. Resolve default schemes (best-effort; missing values are fine, Jira will use
#    its built-in defaults if we omit them).
$permissionScheme = $null
$notificationScheme = 10000  # Jira's documented default
$issueSecurityScheme = $null
$projectCategory = $null

try {
    $ps = (Invoke-RestMethod -Uri "$baseUrl/rest/api/2/permissionscheme" -Method Get -Headers $headers -TimeoutSec 30).permissionSchemes
    if ($ps) {
        $default = $ps | Where-Object { $_.name -eq 'Default Permission Scheme' } | Select-Object -First 1
        if (-not $default) { $default = $ps | Select-Object -First 1 }
        if ($default) { $permissionScheme = [int]$default.id }
    }
}
catch {
    Write-Host "    (permissionscheme lookup skipped: $($_.Exception.Message))"
}

try {
    $iss = Invoke-RestMethod -Uri "$baseUrl/rest/api/2/issuesecurityschemes" -Method Get -Headers $headers -TimeoutSec 30
    $list = if ($iss.issueSecuritySchemes) { $iss.issueSecuritySchemes } else { $iss }
    if ($list) {
        $default = $list | Where-Object { $_.name -eq 'Default' } | Select-Object -First 1
        if (-not $default) { $default = $list | Select-Object -First 1 }
        if ($default) { $issueSecurityScheme = [int]$default.id }
    }
}
catch {
    Write-Host "    (issuesecurityschemes lookup skipped: $($_.Exception.Message))"
}

try {
    $cats = Invoke-RestMethod -Uri "$baseUrl/rest/api/2/projectCategory" -Method Get -Headers $headers -TimeoutSec 30
    if ($cats) {
        $default = $cats | Where-Object { $_.name -eq 'Default' } | Select-Object -First 1
        if (-not $default) { $default = $cats | Select-Object -First 1 }
        if ($default) { $projectCategory = [int]$default.id }
    }
}
catch {
    Write-Host "    (projectCategory lookup skipped: $($_.Exception.Message))"
}

Write-Host ("    Resolved schemes: permission={0} notification={1} security={2} category={3}" -f $permissionScheme, $notificationScheme, $issueSecurityScheme, $projectCategory)

# Diagnostic: dump what project types and templates the running instance actually
# advertises so future debugging doesn't need another CI round-trip.
try {
    $projectTypes = Invoke-RestMethod -Uri "$baseUrl/rest/api/2/project/type" -Method Get -Headers $headers -TimeoutSec 30
    if ($projectTypes) {
        Write-Host ("    Available project types: {0}" -f (($projectTypes | ForEach-Object { $_.key }) -join ', '))
    }
}
catch {
    Write-Host "    (project/type lookup failed: $($_.Exception.Message))"
}

# 2a. Discover the (projectTypeKey, projectTemplateKey) pairs the running
#     instance actually supports. Jira Server/DC exposes them via
#     /rest/project-templates/1.0/templates — both flat (`projectTemplates`)
#     and grouped (`projectTemplatesGroupedByType`) shapes; the AMPS standalone
#     image returns ONLY the grouped shape with a single `business` group.
$discoveredPairs = [System.Collections.Generic.List[hashtable]]::new()
try {
    $rawTemplates = Invoke-RestMethod -Uri "$baseUrl/rest/project-templates/1.0/templates" -Method Get -Headers $headers -TimeoutSec 30

    if ($rawTemplates.projectTemplates) {
        foreach ($tpl in @($rawTemplates.projectTemplates)) {
            $typeKey = $tpl.projectTypeKey
            if (-not $typeKey -and $tpl.projectTypeBean) { $typeKey = $tpl.projectTypeBean.projectTypeKey }
            $tplKey = $tpl.projectTemplateKey
            if ($typeKey -and $tplKey) {
                $discoveredPairs.Add(@{ ProjectTypeKey = $typeKey; ProjectTemplateKey = $tplKey; Source = 'flat' })
            }
        }
    }

    if ($rawTemplates.projectTemplatesGroupedByType) {
        foreach ($group in @($rawTemplates.projectTemplatesGroupedByType)) {
            $typeKey = if ($group.projectTypeBean) { $group.projectTypeBean.projectTypeKey } else { $null }
            foreach ($tpl in @($group.projectTemplates)) {
                $tplKey = $tpl.projectTemplateKey
                if ($typeKey -and $tplKey) {
                    $discoveredPairs.Add(@{ ProjectTypeKey = $typeKey; ProjectTemplateKey = $tplKey; Source = 'grouped' })
                }
            }
        }
    }

    Write-Host ("    Discovered {0} (type, template) pair(s) from /rest/project-templates/1.0/templates:" -f $discoveredPairs.Count)
    foreach ($p in $discoveredPairs) {
        Write-Host ("        [{0}] {1} / {2}" -f $p.Source, $p.ProjectTypeKey, $p.ProjectTemplateKey)
    }

    if ($discoveredPairs.Count -eq 0) {
        # Strip the base64 SVG icons before dumping so we can actually see structure.
        $copy = $rawTemplates | Select-Object * -ExcludeProperty icon
        $rawBody = $copy | ConvertTo-Json -Depth 6 -Compress
        if ($rawBody.Length -gt 4000) { $rawBody = $rawBody.Substring(0, 4000) + '...' }
        Write-Host ("    /rest/project-templates/1.0/templates returned no usable templates. Raw body (icons stripped): {0}" -f $rawBody)
    }
}
catch {
    Write-Host "    (project-templates discovery failed: $($_.Exception.Message))"
}

# Also check whether a project already exists (idempotent re-runs, or if the
# image happens to ship one).
try {
    $existing = Invoke-RestMethod -Uri "$baseUrl/rest/api/2/project" -Method Get -Headers $headers -TimeoutSec 30
    if ($existing) {
        $names = ($existing | ForEach-Object { "$($_.key) ($($_.projectTypeKey))" }) -join ', '
        Write-Host ("    Existing projects: {0}" -f $names)
    }
    else {
        Write-Host "    No existing projects."
    }
}
catch {
    Write-Host "    (project list failed: $($_.Exception.Message))"
}

# 2b. Build the candidate list. Discovered pairs come first (they are guaranteed
#     to exist on this instance); within the discovered set, prefer templates
#     whose key contains 'task' or 'software-development' since those reliably
#     ship the 'Task' issuetype that the Server-tagged integration tests assume
#     (New-JiraIssue -IssueType 'Task'). The hardcoded canonical Server pairs
#     only run if discovery returned nothing.
$rankedDiscovered = @($discoveredPairs | Sort-Object -Property @{
        Expression = {
            $key = $_.ProjectTemplateKey
            switch -Wildcard ($key) {
                '*task-tracking*' { 0 }
                '*basic-software-development*' { 1 }
                '*task*' { 2 }
                '*software*' { 3 }
                '*project-management*' { 4 }
                default { 5 }
            }
        }
    })

$fallbackPairs = @(
    @{ ProjectTypeKey = 'software'; ProjectTemplateKey = 'com.pyxis.greenhopper.jira:basic-software-development-template' }
    @{ ProjectTypeKey = 'business'; ProjectTemplateKey = 'com.atlassian.jira-core-project-templates:jira-core-simplified-task-tracking' }
    @{ ProjectTypeKey = 'business'; ProjectTemplateKey = 'com.atlassian.jira-core-project-templates:jira-core-simplified-process-control' }
    @{ ProjectTypeKey = 'business'; ProjectTemplateKey = 'com.atlassian.jira-core-project-templates:jira-core-simplified-project-management' }
)
$candidatePairs = @()
$candidatePairs += $rankedDiscovered
$candidatePairs += $fallbackPairs

$project = $null
$lastError = $null
foreach ($pair in $candidatePairs) {
    $payload = [ordered]@{
        name               = $ProjectName
        key                = $ProjectKey
        projectTypeKey     = $pair.ProjectTypeKey
        projectTemplateKey = $pair.ProjectTemplateKey
        lead               = $AdminUser
        assigneeType       = 'PROJECT_LEAD'
        description        = 'Created by Tools/Wait-JiraServer.ps1 for JiraPS integration tests. Safe to delete.'
        notificationScheme = $notificationScheme
    }
    if ($permissionScheme) { $payload['permissionScheme'] = $permissionScheme }
    if ($issueSecurityScheme) { $payload['issueSecurityScheme'] = $issueSecurityScheme }
    if ($projectCategory) { $payload['categoryId'] = $projectCategory }

    $body = $payload | ConvertTo-Json -Compress

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
    # Provisioning failed for every candidate pair — this is now a hard failure.
    #
    # If /rest/project-templates/1.0/templates returned discovered pairs and
    # they all rejected, something material has changed (image upgrade, plugin
    # disabled, etc.) and downstream tests will be unable to run anyway. The
    # readiness probe should fail loudly rather than silently degrade so the
    # next CI run surfaces the regression instead of skipping.
    #
    # If discovery returned NO pairs AND every fallback also failed, the
    # instance is so bare that integration tests cannot run; same conclusion.
    Write-Error "Project '$ProjectKey' could not be provisioned with any of the $($candidatePairs.Count) candidate (type, template) pair(s). Last error: $lastError"
    exit 3
}

Write-Host "==> Seeding baseline issue in project '$ProjectKey'"

# Discover an issuetype that this project actually accepts (business projects
# don't ship the Software 'Task' type by default). The /createmeta endpoint
# returns the project's createable issuetypes; pick the first non-subtask one
# and fall back to a hardcoded list of conventional names if discovery fails.
$issueTypeName = $null
try {
    $createMeta = Invoke-RestMethod -Uri "$baseUrl/rest/api/2/issue/createmeta?projectKeys=$ProjectKey" -Method Get -Headers $headers -TimeoutSec 30
    if ($createMeta.projects) {
        $proj = $createMeta.projects | Where-Object { $_.key -eq $ProjectKey } | Select-Object -First 1
        if ($proj.issuetypes) {
            $candidate = $proj.issuetypes | Where-Object { -not $_.subtask } | Select-Object -First 1
            if (-not $candidate) { $candidate = $proj.issuetypes | Select-Object -First 1 }
            if ($candidate) { $issueTypeName = $candidate.name }
        }
    }
    if ($issueTypeName) {
        Write-Host ("    Using discovered issuetype: '{0}'" -f $issueTypeName)
    }
    else {
        Write-Host "    /createmeta returned no issuetypes for '$ProjectKey'; falling back to conventional names."
    }
}
catch {
    Write-Host "    (createmeta lookup failed: $($_.Exception.Message))"
}

$issueTypeCandidates = @()
if ($issueTypeName) { $issueTypeCandidates += $issueTypeName }
$issueTypeCandidates += @('Task', 'Story', 'Bug', 'New Feature')

$issue = $null
$lastIssueError = $null
foreach ($itName in ($issueTypeCandidates | Select-Object -Unique)) {
    $issueBody = @{
        fields = @{
            project     = @{ key = $ProjectKey }
            summary     = 'JiraPS-IntTest-Baseline'
            issuetype   = @{ name = $itName }
            description = 'Baseline issue created by Tools/Wait-JiraServer.ps1. Safe to delete.'
        }
    } | ConvertTo-Json -Depth 5 -Compress

    try {
        $issue = Invoke-RestMethod -Uri $issueApiUrl -Method Post -Headers $headers -ContentType 'application/json' -Body $issueBody -TimeoutSec 30
        Write-Host ("==> Seeded baseline issue: key={0} (issuetype='{1}')" -f $issue.key, $itName)
        break
    }
    catch {
        $issueStatus = $null
        if ($_.Exception.Response) {
            try { $issueStatus = [int]$_.Exception.Response.StatusCode } catch { $issueStatus = $null }
        }
        $issueBodyText = if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $_.ErrorDetails.Message } else { $null }
        $lastIssueError = "status=$issueStatus issuetype='$itName' message=$($_.Exception.Message) body=$issueBodyText"
        Write-Host ("    issuetype '{0}' rejected: {1}" -f $itName, $lastIssueError)
    }
}

if (-not $issue) {
    # Non-fatal — most tests create their own issues. Just log and continue.
    Write-Host "==> Baseline issue creation failed for every candidate. Last error: $lastIssueError"
    Write-Host "==> Continuing — tests that require an existing issue may skip."
}

# Export the provisioned fixture identifiers to GITHUB_ENV so the next workflow
# steps inherit them as JIRA_TEST_PROJECT / JIRA_TEST_ISSUE. This is what makes
# the dynamic Server fixture visible to integration test files that gate on
# `$testEnv.TestIssue` (e.g. Get-JiraIssue.Integration.Tests.ps1) — without it
# those tests self-skip even though the project + baseline issue are present.
# Locally ($env:GITHUB_ENV unset) this is a no-op; users seed the same vars in
# their .env file.
if ($env:GITHUB_ENV) {
    $exports = @()
    if ($project -and $project.key) { $exports += "JIRA_TEST_PROJECT=$($project.key)" }
    if ($issue -and $issue.key) { $exports += "JIRA_TEST_ISSUE=$($issue.key)" }

    if ($exports.Count -gt 0) {
        Add-Content -Path $env:GITHUB_ENV -Value ($exports -join [Environment]::NewLine)
        Write-Host ("==> Exported to GITHUB_ENV: {0}" -f ($exports -join '; '))
    }
}

Write-Host "==> Jira is ready, the test user is provisioned, and the test project '$ProjectKey' is available."
exit 0
