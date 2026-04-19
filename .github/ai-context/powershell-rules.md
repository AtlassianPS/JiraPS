# PowerShell Development Rules

These rules apply to all `.ps1`, `.psm1`, and `.psd1` files in JiraPS.

## Jira Cloud vs Data Center Compatibility

JiraPS targets both Jira Cloud and Jira Data Center. These are different
products with different API behaviors. Any change to API endpoints, request
bodies, or response handling MUST work on both deployment types.

### User Identity (Critical)

- Cloud uses `accountId` (GDPR removed `username`/`name`)
- Data Center uses `username` / `name`
- If a function uses `?username=` or `@{name=...}`, it only works on DC
- If a function uses `?accountId=` or `@{accountId=...}`, it only works on Cloud
- Correct approach: branch based on deployment type

To find functions that need this branching, search `JiraPS/Public/` for cmdlets that:
- Take a `User`/`Assignee`/`Reporter` parameter, **or**
- Build a request body containing `username`, `name`, `accountId`, or `assignee`/`reporter` keys, **or**
- Call `/rest/api/2/user`, `/rest/api/3/user`, or `/group/member` endpoints

Group/watcher membership cmdlets and `Resolve-JiraUser` are also affected.

### Text Fields (ADF vs Plain Text)

- Cloud v3: description, comment body use Atlassian Document Format (ADF) — JSON with `type: "doc"`
- Data Center: these fields are plain strings or wiki markup
- Sending ADF to DC produces garbled content or API errors
- `ConvertTo-ADF` / `ConvertFrom-ADF` must only be used for Cloud

### Search Endpoint

- Cloud: `POST /rest/api/3/search/jql` (JSON body, token pagination)
- Data Center: `GET /rest/api/2/search` (query params, offset pagination)
- These are NOT interchangeable

### API Version

- Do NOT blindly swap `/rest/api/2/` to `/rest/api/3/`
- Cloud is migrating to v3; Data Center retains full v2 support
- Endpoint version changes must be deployment-aware

### Deployment Detection

- `Get-JiraServerInformation` returns `deploymentType` (`Cloud` or `Server`)
- Use this value to branch Cloud/DC-specific logic

## PowerShell Patterns

### REST API Calls

All HTTP calls go through `Invoke-JiraMethod`:

```powershell
$parameter = @{
    URI    = "$($script:JiraServerUrl)/rest/api/2/issue/$IssueKey"
    Method = "GET"
}
$result = Invoke-JiraMethod @parameter
```

### Type Conversion

Use `ConvertTo-*` functions to transform API responses:

```powershell
$result = Invoke-JiraMethod @parameter
ConvertTo-JiraIssue -InputObject $result
```

### Parameter Patterns

```powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [ValidateNotNullOrEmpty()]
    [String]$IssueKey,

    [PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty
)
```

### Error Handling

```powershell
try {
    $result = Invoke-JiraMethod @params
} catch {
    $PSCmdlet.ThrowTerminatingError($_)
}
```

## Testing Requirements

- Every function needs a corresponding `.Unit.Tests.ps1` file
- Use Pester 5 syntax
- Public functions: `Tests/Functions/Public/<FunctionName>.Unit.Tests.ps1`
- Private functions: `Tests/Functions/Private/<FunctionName>.Unit.Tests.ps1`
- Use `.template.ps1` files as starting points
- Tests must cover both Cloud and DC response shapes
- Integration tests (live Jira Cloud) live in `Tests/Integration/<Feature>.Integration.Tests.ps1` — see [`Tests/Integration/README.md`](../../Tests/Integration/README.md)

## Running Tests

**IMPORTANT**: Unit tests run against the *built* module in `Release/`, not source files.
You MUST build before running unit tests. Integration tests load the source manifest directly (no build required) but need live Jira Cloud credentials in `.env`.

```powershell
# First time setup (install dependencies)
./Tools/setup.ps1

# Unit tests (standard workflow)
Invoke-Build -Task Build, Test

# Or separately:
Invoke-Build -Task Build    # Compiles module into Release/
Invoke-Build -Task Test     # Runs unit tests against Release/ (excludes Integration)

# Integration tests (no build needed, requires .env)
Invoke-Build -Task TestIntegration
Invoke-Build -Task TestIntegration -Tag 'Smoke'         # Smoke subset only
Invoke-Build -Task TestIntegration -ThrottleLimit 8     # More parallelism
```

### Available Build Tasks

| Task | What it does |
|------|--------------|
| `Clean` | Removes `Release/` and test artifacts |
| `Build` | Compiles module into `Release/` (includes Clean) |
| `Test` | Runs unit tests against built module (excludes Integration) |
| `TestIntegration` | Runs integration tests in parallel (no build needed) |
| `GenerateExternalHelp` | Generates help XML from `docs/` markdown |
| `Publish` | Publishes to PowerShell Gallery (release tags only) |

### Common Mistakes

- **Running `Invoke-Pester` directly** — Won't work for unit tests; they expect the compiled module
- **Running `Invoke-Build -Task Test` without building** — Tests will fail or use stale code
- **Forgetting `./Tools/setup.ps1`** — Missing dependencies (Pester, InvokeBuild, etc.)
- **Running `TestIntegration` without `.env`** — Will fail fast on missing credentials

## Review Checklist

When changing PowerShell files:

1. Does the change work on BOTH Cloud and Data Center?
2. If user identity is involved: is `accountId` used for Cloud and `username`/`name` for DC?
3. If text fields are read/written: is ADF conversion conditional on deployment type?
4. Are tests written/updated?
5. Do tests pass? (`Invoke-Build -Task Build && Invoke-Build -Task Test`)
