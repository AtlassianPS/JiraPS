. "$PSScriptRoot/TestTools.ps1"

$script:TestResourcePrefix = 'JiraPS-IntTest-'
$script:_CachedIntegrationEnv = $null
$script:_EnvLoaded = $false
$script:_CleanupInProgress = $false

function Read-DotEnvFile {
    <#
    .SYNOPSIS
        Loads KEY=value pairs from a .env file into the current process environment.

    .DESCRIPTION
        Parses a .env-style file:
          - Whole-line comments (`# ...`) and blank lines are skipped.
          - Quoted values (single or double) are taken verbatim between the
            matching quotes, so `#` inside quotes is preserved (relevant for
            secrets like API tokens that may contain `#`).
          - Unquoted values support a trailing inline comment, but only when
            preceded by whitespace (`KEY=value  # comment`). A bare `#` inside
            an unquoted value (e.g. `KEY=foo#bar`) is treated as part of the
            value, not a comment marker.

        Each parsed assignment is set via
        [System.Environment]::SetEnvironmentVariable so it is visible through
        $env:NAME for the lifetime of the process.

    .PARAMETER Path
        Path to the .env file. The function silently no-ops if the file does not
        exist so callers can opt-in without checking first.

    .EXAMPLE
        Read-DotEnvFile -Path (Join-Path $projectRoot '.env')
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Reading a .env file into process env vars is intentional and idempotent')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    Get-Content -LiteralPath $Path | ForEach-Object {
        $line = $_
        if ($line -match '^\s*#' -or $line -match '^\s*$') { return }
        if ($line -notmatch '^\s*([^#=]+?)\s*=\s*(.*)$') { return }

        $name = $matches[1].Trim()
        if ([string]::IsNullOrEmpty($name)) { return }

        $rawValue = $matches[2].TrimStart()

        if ($rawValue.Length -gt 0 -and ($rawValue[0] -eq '"' -or $rawValue[0] -eq "'")) {
            # Quoted value: take everything between the opening quote and the
            # next matching quote. Anything after the closing quote is ignored
            # (acts as an inline comment).
            $quote = $rawValue[0]
            $endIdx = $rawValue.IndexOf($quote, 1)
            $value = if ($endIdx -gt 0) {
                $rawValue.Substring(1, $endIdx - 1)
            }
            else {
                # Unterminated quote - take the rest of the line verbatim,
                # minus the opening quote.
                $rawValue.Substring(1)
            }
        }
        else {
            # Unquoted value: only treat ` #` (whitespace + #) as the start
            # of an inline comment so `#` characters inside the value survive.
            if ($rawValue -match '^(.*?)\s+#') {
                $value = $matches[1]
            }
            else {
                $value = $rawValue
            }
            $value = $value.TrimEnd()
        }

        [System.Environment]::SetEnvironmentVariable($name, $value)
    }
}

function Initialize-IntegrationEnvironment {
    <#
    .SYNOPSIS
        Loads and validates integration test environment configuration.

    .DESCRIPTION
        This function loads environment variables from a .env file and validates
        that all required variables for integration testing are present.

        The function looks for .env in the project root directory.

        Results are cached to avoid redundant .env parsing when called multiple
        times (e.g., from both BeforeDiscovery and BeforeAll in the same process).

    .OUTPUTS
        [PSCustomObject] Configuration object with all environment settings, or $null if not configured.

    .EXAMPLE
        BeforeDiscovery {
            . "$PSScriptRoot/../../Helpers/IntegrationTestTools.ps1"
            $script:integrationEnv = Initialize-IntegrationEnvironment
            if (-not $integrationEnv) {
                $script:Skip = $true
            }
        }

    .NOTES
        Returns $null if required environment variables are missing, allowing tests
        to be skipped gracefully when not configured.

        Uses a global variable (`$global:_JiraPSIntegrationEnvWarned`) to ensure
        the "missing env vars" warning fires at most once per PowerShell process.
        A script-scoped flag would not work because Pester dot-sources this file
        in every integration test's BeforeDiscovery block, resetting any
        script-scoped state.

        .env format: KEY=value (no quotes needed around values)
        - Lines starting with # are comments
        - Inline comments (KEY=value # comment) are stripped
        - Surrounding quotes on values are stripped
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Process-wide warn-once flag; a script-scoped flag resets every time Pester dot-sources this file from BeforeDiscovery.')]
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    if ($script:_EnvLoaded) {
        return $script:_CachedIntegrationEnv
    }

    $projectRoot = Resolve-ProjectRoot

    $envFile = Join-Path $projectRoot '.env'
    if (Test-Path $envFile) {
        Read-DotEnvFile -Path $envFile
        Write-Verbose "Loaded environment from: $envFile"
    }

    # CI_JIRA_TYPE selects the deployment target for this test run. 'Cloud' is the
    # historical default and is what the Cloud workflow drives; 'Server' is set by
    # the jira_server_ci.yml workflow (and locally by the StartJiraDocker task).
    $deploymentType = if ($env:CI_JIRA_TYPE) { $env:CI_JIRA_TYPE } else { 'Cloud' }
    if ($deploymentType -notin @('Cloud', 'Server')) {
        throw "Invalid CI_JIRA_TYPE '$deploymentType'. Must be 'Cloud' or 'Server'."
    }

    $requiredVars = if ($deploymentType -eq 'Server') {
        @(
            'CI_JIRA_URL'
            'CI_JIRA_ADMIN'
            'CI_JIRA_ADMIN_PASSWORD'
            'CI_JIRA_USER'
            'CI_JIRA_USER_PASSWORD'
        )
    }
    else {
        @(
            'JIRA_CLOUD_URL'
            'JIRA_CLOUD_USERNAME'
            'JIRA_CLOUD_PASSWORD'
            'JIRA_TEST_PROJECT'
            'JIRA_TEST_ISSUE'
        )
    }

    $missing = @()
    foreach ($var in $requiredVars) {
        if ([string]::IsNullOrEmpty([Environment]::GetEnvironmentVariable($var))) {
            $missing += $var
        }
    }

    if ($missing.Count -gt 0) {
        # Warn once per PowerShell process. The `$script:` cache resets every
        # time this file is dot-sourced (Pester does so in each integration
        # test's BeforeDiscovery), so a script-scoped guard would still spam
        # the warning N times. A process-wide global flag stays set across
        # every dot-source within the same runspace.
        if (-not $global:_JiraPSIntegrationEnvWarned) {
            Write-Warning "Integration tests ($deploymentType track) require the following environment variables: $($missing -join ', ')"
            if ($deploymentType -eq 'Server') {
                Write-Warning "Set CI_JIRA_TYPE=Server and the CI_JIRA_* vars (defaults match the moveworkforward/atlas-run-standalone Docker image). See .env.example."
            }
            else {
                Write-Warning "Copy .env.example to .env and configure your Jira Cloud connection."
            }
            $global:_JiraPSIntegrationEnvWarned = $true
        }
        $script:_EnvLoaded = $true
        $script:_CachedIntegrationEnv = $null
        return $null
    }

    if ($deploymentType -eq 'Server') {
        $result = [PSCustomObject]@{
            DeploymentType = 'Server'
            IsCloud        = $false
            UserIdProperty = 'name'
            CloudUrl       = $env:CI_JIRA_URL.TrimEnd('/')
            Username       = $env:CI_JIRA_ADMIN
            Password       = $env:CI_JIRA_ADMIN_PASSWORD
            UsernameNormal = $env:CI_JIRA_USER
            PasswordNormal = $env:CI_JIRA_USER_PASSWORD
            HasNormalUser  = -not [string]::IsNullOrEmpty($env:CI_JIRA_USER)
            # Server track creates fixtures dynamically; the bare moveworkforward image
            # ships with no project, so most tests should fall back to creating their own
            # resources (or skip with a clear message) rather than assuming a permanent fixture.
            TestProject    = if ($env:JIRA_TEST_PROJECT) { $env:JIRA_TEST_PROJECT } else { 'TEST' }
            TestIssue      = $null
            TestUser       = $env:CI_JIRA_USER
            TestGroup      = $env:JIRA_TEST_GROUP
            TestFilter     = $null
            TestVersion    = $null
            ReadOnly       = $env:JIRA_TEST_READONLY -eq 'true'
            VerboseOutput  = $env:JIRA_TEST_VERBOSE -eq 'true'
        }
    }
    else {
        $result = [PSCustomObject]@{
            DeploymentType = 'Cloud'
            IsCloud        = $true
            UserIdProperty = 'accountId'
            CloudUrl       = $env:JIRA_CLOUD_URL.TrimEnd('/')
            Username       = $env:JIRA_CLOUD_USERNAME
            Password       = $env:JIRA_CLOUD_PASSWORD
            UsernameNormal = $env:JIRA_CLOUD_USERNAME_NORMAL
            PasswordNormal = $env:JIRA_CLOUD_PASSWORD_NORMAL
            HasNormalUser  = (-not [string]::IsNullOrEmpty($env:JIRA_CLOUD_USERNAME_NORMAL)) -and
            (-not [string]::IsNullOrEmpty($env:JIRA_CLOUD_PASSWORD_NORMAL))
            TestProject    = $env:JIRA_TEST_PROJECT
            TestIssue      = $env:JIRA_TEST_ISSUE
            TestUser       = $env:JIRA_TEST_USER
            TestGroup      = $env:JIRA_TEST_GROUP
            TestFilter     = $env:JIRA_TEST_FILTER
            TestVersion    = $env:JIRA_TEST_VERSION
            ReadOnly       = $env:JIRA_TEST_READONLY -eq 'true'
            VerboseOutput  = $env:JIRA_TEST_VERBOSE -eq 'true'
        }
    }

    $script:_EnvLoaded = $true
    $script:_CachedIntegrationEnv = $result
    return $result
}

function Connect-JiraTestServer {
    <#
    .SYNOPSIS
        Establishes an authenticated session with the test Jira instance.

    .DESCRIPTION
        Configures the JiraPS module to connect to the test Jira instance (Cloud or
        Data Center, depending on `$Environment.IsCloud`) and creates an authenticated
        session using the credentials from the environment configuration.

        - Cloud: uses `New-JiraSession -ApiToken -EmailAddress` (Atlassian API token).
        - Data Center: uses `New-JiraSession -Credential` with admin Basic auth (the
          moveworkforward/atlas-run-standalone Docker container ships with `admin/admin`
          and Wait-JiraServer.ps1 provisions a normal user on top).

        Only calls Set-JiraConfigServer if the URL differs from current config,
        avoiding unnecessary file writes in parallel test runs.

    .PARAMETER Environment
        The environment configuration object from Initialize-IntegrationEnvironment.
        If not provided, will call Initialize-IntegrationEnvironment automatically.

    .OUTPUTS
        [PSCustomObject] The Jira session object.

    .EXAMPLE
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/IntegrationTestTools.ps1"
            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
        }

    .NOTES
        This function should be called in BeforeAll blocks of integration tests.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Test helper requires plaintext conversion for API token from environment')]
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [PSCustomObject]$Environment
    )

    if (-not $Environment) {
        $Environment = Initialize-IntegrationEnvironment
        if (-not $Environment) {
            throw "Integration environment not configured. See .env.example for required variables."
        }
    }

    $currentServer = Get-JiraConfigServer -ErrorAction SilentlyContinue
    if (-not $currentServer -or $currentServer.ToString().TrimEnd('/') -ne $Environment.CloudUrl) {
        Set-JiraConfigServer -Server $Environment.CloudUrl
    }

    if ($Environment.IsCloud) {
        $secureToken = ConvertTo-SecureString -String $Environment.Password -AsPlainText -Force
        $session = New-JiraSession -ApiToken $secureToken -EmailAddress $Environment.Username
        if (-not $session) {
            throw "Failed to establish Jira session. Check credentials and server URL. For Jira Cloud, JIRA_CLOUD_PASSWORD must be an API token (not your account password)."
        }
        Write-Verbose "Connected to Jira Cloud: $($Environment.CloudUrl)"
    }
    else {
        # Server / Data Center: send Basic auth proactively via the Authorization
        # header instead of relying on `Invoke-WebRequest -Credential` (which uses
        # challenge-response auth and fails when Atlassian Seraph's 401 omits a
        # `WWW-Authenticate: Basic` header on /myself).
        $authPair = "$($Environment.Username):$($Environment.Password)"
        $basicAuthHeader = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($authPair))

        # Diagnostic probe: previous run confirmed Basic auth works against the same
        # endpoint (200 OK with admin user JSON). The remaining mystery is why
        # New-JiraSession ends up returning $null. Re-probe and additionally inspect
        # the Atlassian Seraph LoginReason header (Test-ServerResponse turns
        # AUTHENTICATED_FAILED / AUTHENTICATION_DENIED / AUTHORISATION_FAILED into
        # terminating errors even on 2xx responses), then run New-JiraSession itself
        # inside try/catch with -Verbose so the actual Invoke-JiraMethod call chain
        # (and any error it emits via WriteError → swallowed by default) shows up in
        # the test step log.
        $myselfUrl = "$($Environment.CloudUrl)/rest/api/2/myself"
        Write-Host "==> [Connect-JiraTestServer] probing $myselfUrl with Basic auth (user=$($Environment.Username))"
        try {
            $probe = Invoke-WebRequest -Uri $myselfUrl -Method Get -Headers @{ Authorization = $basicAuthHeader } -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
            $seraph = $null
            try {
                if ($probe.Headers -and $probe.Headers['X-Seraph-LoginReason']) {
                    $seraph = ($probe.Headers['X-Seraph-LoginReason'] -join ',')
                }
            } catch { }
            $allHeaders = $null
            try { $allHeaders = ($probe.Headers.Keys | Sort-Object) -join ',' } catch { }
            Write-Host "==> [Connect-JiraTestServer] probe OK: status=$($probe.StatusCode) X-Seraph-LoginReason=$seraph headers=$allHeaders"
        }
        catch {
            Write-Host "==> [Connect-JiraTestServer] probe FAILED: $($_.Exception.Message)"
        }

        Write-Host "==> [Connect-JiraTestServer] calling New-JiraSession (verbose)"
        $sessionErrors = @()
        $session = $null
        try {
            $session = New-JiraSession -Headers @{ Authorization = $basicAuthHeader } -Verbose -ErrorVariable sessionErrors -ErrorAction Continue 4>&1 | ForEach-Object {
                if ($_ -is [System.Management.Automation.VerboseRecord]) {
                    Write-Host "    [verbose] $($_.Message)"
                } else {
                    $_
                }
            } | Select-Object -Last 1
        }
        catch {
            Write-Host "==> [Connect-JiraTestServer] New-JiraSession threw: $($_.Exception.GetType().FullName): $($_.Exception.Message)"
        }
        if ($sessionErrors) {
            foreach ($e in $sessionErrors) {
                Write-Host "==> [Connect-JiraTestServer] New-JiraSession error: $($e.Exception.GetType().FullName): $($e.Exception.Message)"
            }
        }
        Write-Host "==> [Connect-JiraTestServer] New-JiraSession returned: type=$($session.GetType().FullName 2>$null) value=$session"

        if (-not $session) {
            throw "Failed to establish Jira session. Check credentials and server URL. For Jira Data Center, CI_JIRA_ADMIN_PASSWORD must be the admin user's password (default: 'admin' for the moveworkforward/atlas-run-standalone image)."
        }
        Write-Verbose "Connected to Jira Data Center: $($Environment.CloudUrl)"
    }

    # Sweep stale resources from previous failed runs once per runspace.
    # Remove-StaleTestResource short-circuits via $script:_CleanupInProgress, so
    # subsequent connects in the same runspace are no-ops. Across parallel
    # runspaces each performs the sweep once - the underlying Remove-* calls
    # use -ErrorAction SilentlyContinue, so concurrent races are absorbed.
    if (-not $Environment.ReadOnly) {
        try {
            Remove-StaleTestResource -Fixtures (Get-TestFixture -Environment $Environment) -ErrorAction SilentlyContinue
        }
        catch {
            Write-Warning "Stale resource cleanup encountered an error (non-fatal): $_"
        }
    }

    return $session
}

function Get-TestFixture {
    <#
    .SYNOPSIS
        Returns a hashtable of test fixture references.

    .DESCRIPTION
        This function returns a hashtable containing references to test fixtures
        (project, issue, user, etc.) that can be used in integration tests.

    .PARAMETER Environment
        The environment configuration object from Initialize-IntegrationEnvironment.
        If not provided, will call Initialize-IntegrationEnvironment automatically.

    .OUTPUTS
        [hashtable] Test fixture references.

    .EXAMPLE
        BeforeAll {
            $script:fixtures = Get-TestFixture
        }

        It "retrieves the test issue" {
            $issue = Get-JiraIssue -Key $fixtures.TestIssue
            $issue | Should -Not -BeNullOrEmpty
        }
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter()]
        [PSCustomObject]$Environment
    )

    if (-not $Environment) {
        $Environment = Initialize-IntegrationEnvironment
        if (-not $Environment) {
            throw "Integration environment not configured. See .env.example for required variables."
        }
    }

    @{
        TestProject    = $Environment.TestProject
        TestIssue      = $Environment.TestIssue
        TestUser       = $Environment.TestUser
        TestGroup      = $Environment.TestGroup
        TestFilter     = $Environment.TestFilter
        TestVersion    = $Environment.TestVersion
        CloudUrl       = $Environment.CloudUrl
        ReadOnly       = $Environment.ReadOnly
        DeploymentType = $Environment.DeploymentType
        IsCloud        = $Environment.IsCloud
        UserIdProperty = $Environment.UserIdProperty
    }
}

function Skip-IntegrationTest {
    <#
    .SYNOPSIS
        Determines whether integration tests should be skipped.

    .DESCRIPTION
        Returns $true if the integration environment is not configured,
        allowing tests to be skipped gracefully in CI/CD when secrets
        are not available.

    .OUTPUTS
        [bool] $true if tests should be skipped, $false otherwise.

    .EXAMPLE
        BeforeDiscovery {
            . "$PSScriptRoot/../../Helpers/IntegrationTestTools.ps1"
            $script:Skip = Skip-IntegrationTest
        }

        Describe "My Test" -Skip:$Skip {
            # Tests here
        }
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $config = Initialize-IntegrationEnvironment -ErrorAction SilentlyContinue
    return ($null -eq $config)
}

function New-TemporaryTestIssue {
    <#
    .SYNOPSIS
        Creates a temporary test issue for write tests.

    .DESCRIPTION
        Creates a new issue in the test project that can be used for
        testing create/update/delete operations. The issue should be
        cleaned up after the test using Remove-JiraIssue.

    .PARAMETER Summary
        The summary/title for the test issue.

    .PARAMETER Fixtures
        The test fixtures hashtable from Get-TestFixture.

    .OUTPUTS
        [PSCustomObject] The created issue object.

    .EXAMPLE
        BeforeAll {
            $script:tempIssue = New-TemporaryTestIssue -Summary "Test Issue $(Get-Date -Format 'yyyyMMddHHmmss')"
        }

        AfterAll {
            if ($tempIssue -and $tempIssue.Key) {
                Remove-JiraIssue -IssueId $tempIssue.Key -Force -ErrorAction SilentlyContinue
            }
        }
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test helper for creating test data does not require confirmation')]
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter()]
        [string]$Summary,

        [Parameter()]
        [hashtable]$Fixtures
    )

    if (-not $Fixtures) {
        $Fixtures = Get-TestFixture
    }

    if ($Fixtures.ReadOnly) {
        throw "Cannot create test issues in read-only mode. Set JIRA_TEST_READONLY=false in .env"
    }

    # Default to a prefixed name so Remove-StaleTestResource can discover it.
    if ([string]::IsNullOrEmpty($Summary)) {
        $Summary = New-TestResourceName -Type 'Issue'
    }

    $issueParams = @{
        Project     = $Fixtures.TestProject
        IssueType   = 'Task'
        Summary     = $Summary
        Description = "Temporary test issue created by JiraPS integration tests. Safe to delete."
    }

    $issue = New-JiraIssue @issueParams
    Write-Verbose "Created temporary test issue: $($issue.Key)"
    return $issue
}

function Remove-StaleTestResource {
    <#
    .SYNOPSIS
        Cleans up stale test resources from previous test runs.

    .DESCRIPTION
        This function searches for and removes test resources that were created
        by previous integration test runs but not properly cleaned up. Resources
        are identified by the test prefix in their names/summaries.

        Run this at the START of your test suite to ensure a clean state.

        In parallel test runs, only the first runner to call this function will
        perform cleanup - subsequent calls are skipped to avoid racing on the
        same resources and wasting API budget.

    .PARAMETER Fixtures
        The test fixtures hashtable from Get-TestFixture.

    .PARAMETER MaxAge
        Maximum age of resources to consider "stale" (default: 1 hour).
        Resources older than this will be deleted.

    .PARAMETER Force
        Force cleanup even if another runner already performed it in this process.

    .EXAMPLE
        BeforeAll {
            $script:fixtures = Get-TestFixture
            Remove-StaleTestResource -Fixtures $fixtures
        }

    .NOTES
        This function is idempotent and safe to call multiple times.
        It only removes resources with the JiraPS-IntTest- prefix.
        "Already deleted" errors from parallel runners are silently ignored.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test helper for cleanup does not require confirmation')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$Fixtures,

        [Parameter()]
        [TimeSpan]$MaxAge = (New-TimeSpan -Hours 1),

        [Parameter()]
        [switch]$Force
    )

    if ($script:_CleanupInProgress -and -not $Force) {
        Write-Verbose "Cleanup already performed or in progress - skipping"
        return
    }
    $script:_CleanupInProgress = $true

    if (-not $Fixtures) {
        $Fixtures = Get-TestFixture
    }

    if ($Fixtures.ReadOnly) {
        Write-Verbose "Read-only mode: skipping stale resource cleanup"
        return
    }

    $cutoffTime = (Get-Date).Add(-$MaxAge)
    $prefix = $script:TestResourcePrefix
    Write-Verbose "Cleaning up test resources older than $cutoffTime with prefix '$prefix'"

    try {
        # Quote the prefix as a phrase so Jira's text search does not tokenize on '-'
        # (which would match any of "JiraPS", "IntTest" individually).
        $jql = "project = $($Fixtures.TestProject) AND summary ~ ""\""$prefix\"""" ORDER BY created ASC"
        $staleIssues = Get-JiraIssue -Query $jql -ErrorAction SilentlyContinue
        foreach ($issue in $staleIssues) {
            if ($issue.Created -lt $cutoffTime) {
                Write-Verbose "Removing stale test issue: $($issue.Key) (created $($issue.Created))"
                Remove-JiraIssue -IssueId $issue.Key -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        Write-Warning "Failed to clean up stale issues: $_"
    }

    try {
        $versions = Get-JiraVersion -Project $Fixtures.TestProject -ErrorAction SilentlyContinue
        foreach ($version in $versions) {
            if ($version.Name -like "$prefix*") {
                Write-Verbose "Removing stale test version: $($version.Name)"
                Remove-JiraVersion -Version $version -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        Write-Warning "Failed to clean up stale versions: $_"
    }

    try {
        $filters = Find-JiraFilter -Name $prefix -ErrorAction SilentlyContinue
        foreach ($filter in $filters) {
            if ($filter.Name -like "$prefix*") {
                Write-Verbose "Removing stale test filter: $($filter.Name)"
                Remove-JiraFilter -InputObject $filter -ErrorAction SilentlyContinue -Confirm:$false
            }
        }
    }
    catch {
        Write-Warning "Failed to clean up stale filters: $_"
    }
}

function Get-TestResourcePrefix {
    <#
    .SYNOPSIS
        Returns the prefix used for test resources.

    .DESCRIPTION
        All temporary test resources should use this prefix in their
        names/summaries to enable automated cleanup.

    .OUTPUTS
        [string] The test resource prefix.

    .EXAMPLE
        $summary = "$(Get-TestResourcePrefix)Issue-$(Get-Date -Format 'yyyyMMddHHmmss')"
        New-JiraIssue -Summary $summary ...
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return $script:TestResourcePrefix
}

function New-TestResourceName {
    <#
    .SYNOPSIS
        Generates a unique name for a test resource with the standard prefix.

    .DESCRIPTION
        Creates a name like "JiraPS-IntTest-Issue-20260412233045-a1b2c3" that is
        easily identifiable as a test resource and unique per invocation.

        Includes a short GUID suffix to ensure uniqueness when multiple parallel
        test runners call this function in the same second.

    .PARAMETER Type
        The type of resource (e.g., "Issue", "Version", "Filter").

    .OUTPUTS
        [string] A unique test resource name.

    .EXAMPLE
        $summary = New-TestResourceName -Type "Issue"
        # Returns: "JiraPS-IntTest-Issue-20260412233045-a1b2c3"
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Function only generates a string, does not modify state')]
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Type
    )

    $guidSuffix = [Guid]::NewGuid().ToString('N').Substring(0, 6)
    return "$($script:TestResourcePrefix)$Type-$(Get-Date -Format 'yyyyMMddHHmmss')-$guidSuffix"
}
