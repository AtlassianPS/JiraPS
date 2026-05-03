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
    # the `server_integration_tests` job in integration_tests.yml (and locally by
    # the StartJiraDocker task).
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
        # Server track fixture sourcing:
        #   - Wait-JiraServer.ps1 (run by the `server_integration_tests` job in
        #     integration_tests.yml and by the StartJiraDocker build task) provisions a TEST project and a TEST-1 baseline issue
        #     against the moveworkforward/atlas-run-standalone image, then exports
        #     JIRA_TEST_PROJECT and JIRA_TEST_ISSUE to $env:GITHUB_ENV.
        #   - Honour those env vars here (same shape as the Cloud branch below) so
        #     read-only smoke tests like `Get-JiraIssue $TestIssue` actually run
        #     against the seeded baseline instead of self-skipping.
        #   - Write tests that need a fresh issue (Add-JiraIssueAttachment,
        #     Add-JiraIssueComment, Add-JiraIssueLink, Add-JiraIssueWorklog, ...)
        #     create their own fixtures via New-TemporaryTestIssue and clean them
        #     up in AfterAll, so they do not depend on these env vars.
        #   - JIRA_TEST_FILTER and JIRA_TEST_VERSION are not provisioned by
        #     Wait-JiraServer.ps1 yet (no per-image fixture for them), so they
        #     stay null on a clean boot and the dependent tests self-skip with a
        #     clear message — but if a follow-up commit teaches Wait-JiraServer.ps1
        #     to seed them, this branch picks the values up automatically.
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
            TestProject    = if ($env:JIRA_TEST_PROJECT) { $env:JIRA_TEST_PROJECT } else { 'TEST' }
            TestIssue      = $env:JIRA_TEST_ISSUE
            TestUser       = $env:CI_JIRA_USER
            TestGroup      = $env:JIRA_TEST_GROUP
            TestFilter     = $env:JIRA_TEST_FILTER
            TestVersion    = $env:JIRA_TEST_VERSION
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
        # Server / Data Center: send Basic auth proactively via an explicit Authorization
        # header. PowerShell's `Invoke-WebRequest -Credential` uses challenge-response
        # (it sends the first request unauthenticated and only retries with credentials
        # if the server responds with `WWW-Authenticate: Basic`). Atlassian Seraph on
        # /rest/api/2/myself does not always advertise Basic in its 401, so the retry
        # never happens and the JiraPS session never gets established. Sending the
        # header up-front bypasses the handshake entirely and matches what
        # Wait-JiraServer.ps1 does successfully against the same image.
        $authPair = "$($Environment.Username):$($Environment.Password)"
        $basicAuthHeader = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($authPair))
        $session = New-JiraSession -Headers @{ Authorization = $basicAuthHeader }
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

        The helper is deployment-aware: it queries the project's createmeta
        for the chosen issue type and auto-populates any required field
        that the server cannot default for itself (project-tightened
        custom fields without a configured default value, project-tightened
        Reporter fields on Jira Data Center where the acting user's
        Resolve-JiraUser response has to be passed explicitly, etc.).
        That makes the helper safe to use against any project — including
        the `jira-core-task-management` template the Server CI track
        provisions, whose default field configuration is stricter than the
        Cloud "next-gen" Task project most read-only tests assume.

        Tests that need to assert default Jira behavior should still call
        `New-JiraIssue` directly. Use this helper any time you just need
        "an issue exists in the test project so we can hang assertions
        off of it".

    .PARAMETER Summary
        The summary/title for the test issue. Defaults to a prefixed
        `JiraPS-IntTest-Issue-<timestamp>-<guid>` name so the cleanup
        sweeper can discover it.

    .PARAMETER Fixtures
        The test fixtures hashtable from Get-TestFixture.

    .PARAMETER IssueType
        The issue type to create. Defaults to 'Task' (the only type guaranteed
        to exist on both the Cloud and the Server `jira-core-task-management`
        template).

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
        [hashtable]$Fixtures,

        [Parameter()]
        [string]$IssueType = 'Task'
    )

    if (-not $Fixtures) {
        $Fixtures = Get-TestFixture
    }

    if ($Fixtures.ReadOnly) {
        throw "Cannot create test issues in read-only mode. Set JIRA_TEST_READONLY=false in .env"
    }

    if ([string]::IsNullOrEmpty($Fixtures.TestProject)) {
        throw "Cannot create test issue without a configured test project (Fixtures.TestProject is empty). Wait-JiraServer.ps1 should set JIRA_TEST_PROJECT for the Server track; for the Cloud track set JIRA_TEST_PROJECT in .env."
    }

    if ([string]::IsNullOrEmpty($Summary)) {
        $Summary = New-TestResourceName -Type 'Issue'
    }

    $issueParams = @{
        Project     = $Fixtures.TestProject
        IssueType   = $IssueType
        Summary     = $Summary
        Description = "Temporary test issue created by JiraPS integration tests. Safe to delete."
    }

    $extras = Get-MinimumValidIssueParameter -Fixtures $Fixtures -IssueType $IssueType -SkipFieldId @('description')
    if ($extras.Reporter) { $issueParams.Reporter = $extras.Reporter }
    if ($extras.Fields -and $extras.Fields.Count -gt 0) { $issueParams.Fields = $extras.Fields }

    $issue = New-JiraIssue @issueParams
    Write-Verbose "Created temporary test issue: $($issue.Key)"
    return $issue
}

function Get-MinimumValidIssueParameter {
    <#
    .SYNOPSIS
        Resolves the project- and issuetype-specific extras that `New-JiraIssue`
        may need in order to create an issue successfully across different Jira
        field configurations.

    .DESCRIPTION
        Probes `Get-JiraIssueCreateMetadata` for the project's chosen issue
        type and computes minimal valid values for any field marked
        `required: true` that does NOT carry `hasDefaultValue: true`. The
        returned hashtable is splat-friendly: `-Reporter` is exposed at the
        top level (matching `New-JiraIssue`'s native parameter), and any
        other tightened fields land in a `-Fields` sub-hashtable.

        This mirrors the logic the Atlassian REST docs document for
        "minimum required payload": Project / IssueType / Summary plus
        whatever extras the project's field configuration tightened. On
        Cloud (and most Server installs) the default Task project has no
        extras and this returns an empty result. On the moveworkforward
        AMPS standalone image the `jira-core-task-management` template
        marks Reporter (and occasionally Priority) as required with no
        default value, so this helper supplies them.

        Tests should call this BEFORE invoking `New-JiraIssue` so the
        resulting cmdlet call exercises the cmdlet end-to-end without
        flapping on cross-deployment field configuration drift.

    .PARAMETER Fixtures
        Test fixtures from `Get-TestFixture`. Provides `TestProject` and
        `TestUser` (the latter is the candidate `Reporter` value).

    .PARAMETER IssueType
        The issue type to probe. Defaults to 'Task'.

    .PARAMETER SkipFieldId
        Field IDs that the caller will provide explicitly and that should
        therefore be skipped from the required-no-default sweep (e.g. when
        the caller already supplies `-Description`, pass `'description'`).

    .OUTPUTS
        Hashtable with the optional keys:
        - Reporter: a string suitable for `New-JiraIssue -Reporter`
        - Fields:   a hashtable suitable for `New-JiraIssue -Fields`

    .EXAMPLE
        $extras = Get-MinimumValidIssueParameter -Fixtures $fixtures
        $params = @{ Project = $fixtures.TestProject; IssueType = 'Task'; Summary = 'foo' }
        if ($extras.Reporter) { $params.Reporter = $extras.Reporter }
        if ($extras.Fields)   { $params.Fields   = $extras.Fields }
        $issue = New-JiraIssue @params
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter()]
        [hashtable]$Fixtures,

        [Parameter()]
        [string]$IssueType = 'Task',

        [Parameter()]
        [string[]]$SkipFieldId = @()
    )

    if (-not $Fixtures) { $Fixtures = Get-TestFixture }

    $result = @{ Reporter = $null; Fields = @{} }

    if ([string]::IsNullOrEmpty($Fixtures.TestProject)) { return $result }

    try {
        $createmeta = Get-JiraIssueCreateMetadata -Project $Fixtures.TestProject -IssueType $IssueType -ErrorAction Stop -Debug:$false
    }
    catch {
        # The createmeta endpoint can legitimately 404 on freshly-provisioned
        # projects (the moveworkforward AMPS image takes a few seconds after
        # project creation before the per-issuetype createmeta route is wired
        # up). Surface it as a Warning rather than Verbose so a regression in
        # the seeding pipeline shows up in the GitHub Actions log immediately
        # instead of cascading into a swarm of less-local Jira create failures
        # further downstream.
        Write-Warning "Get-MinimumValidIssueParameter: createmeta probe for project [$($Fixtures.TestProject)] / issuetype [$IssueType] failed ($($_.Exception.Message)); returning empty extras. Jira may still reject the create call if the project tightens any required-no-default field."
        return $result
    }

    # Determine the username we hand to user-typed required fields. Prefer the
    # provisioned `jira_user` (created by Wait-JiraServer.ps1 with project Browse
    # / Create Issue permissions), fall back to the admin so the helper still
    # works when `Initialize-IntegrationEnvironment` is used by an ad-hoc setup
    # that did not stand up a normal user.
    $userCandidate = if ($Fixtures.TestUser) {
        $Fixtures.TestUser
    }
    elseif ($env:CI_JIRA_USER) {
        $env:CI_JIRA_USER
    }
    else {
        $env:CI_JIRA_ADMIN
    }

    # Fields the New-JiraIssue parameter set already covers via top-level switches.
    $alwaysProvidedById = @('project', 'issuetype', 'summary') + @($SkipFieldId | Where-Object { $_ })

    foreach ($field in @($createmeta)) {
        if (-not $field.Required) { continue }
        if ($field.HasDefaultValue) { continue }
        if ($field.Id -in $alwaysProvidedById) { continue }

        # Reporter and Assignee both surface as `user`-typed required fields on
        # the moveworkforward AMPS image's `jira-core-task-management` template
        # (the field configuration ships with both flagged Required without a
        # configured default). New-JiraIssue exposes a top-level -Reporter param
        # (so we route via $result.Reporter), but it has no top-level -Assignee
        # equivalent for the create path — we therefore drop assignee into
        # $result.Fields so it ends up in the request payload.
        if ($field.Id -eq 'reporter' -and $userCandidate) {
            $result.Reporter = $userCandidate
            continue
        }
        if ($field.Id -eq 'assignee' -and $userCandidate) {
            $result.Fields['assignee'] = @{ name = "$userCandidate" }
            continue
        }

        $allowed = @($field.AllowedValues)
        if ($allowed.Count -gt 0) {
            $first = $allowed[0]
            # Prefer {id:...} since it is universally accepted; fall back to {name:...}.
            $result.Fields[$field.Id] = if ($first.id) { @{ id = "$($first.id)" } } else { @{ name = "$($first.name)" } }
            continue
        }

        switch ($field.Schema.type) {
            'string' { $result.Fields[$field.Id] = "JiraPS-IntTest default for $($field.Name)"; break }
            'number' { $result.Fields[$field.Id] = 0; break }
            'array' { $result.Fields[$field.Id] = @(); break }
            'user' {
                # Generic catch-all for `user`-typed required fields beyond
                # reporter/assignee (e.g. custom approver fields the project
                # template might add). The `name` payload shape works on
                # Server / Data Center; on Cloud the helper stays silent for
                # these fields since createmeta there does not surface them
                # without `hasDefaultValue: true`.
                if ($userCandidate) {
                    $result.Fields[$field.Id] = @{ name = "$userCandidate" }
                }
                else {
                    Write-Warning "Get-MinimumValidIssueParameter: required user field [$($field.Name)] (id=[$($field.Id)]) cannot be defaulted because no test user is configured."
                }
                break
            }
            default {
                Write-Warning "Get-MinimumValidIssueParameter: required field [$($field.Name)] (id=[$($field.Id)], type=[$($field.Schema.type)]) has no AllowedValues, no HasDefaultValue, and no schema-derived default; New-JiraIssue may still reject the create call. Extend Get-MinimumValidIssueParameter in Tests/Helpers/IntegrationTestTools.ps1 to handle this field type."
            }
        }
    }

    return $result
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
