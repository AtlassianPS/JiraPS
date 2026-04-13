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

Affected functions: `Get-JiraUser`, `Set-JiraUser`, `Remove-JiraUser`,
`New-JiraIssue` (reporter), `Set-JiraIssue` (assignee),
`Invoke-JiraIssueTransition`, `Add-JiraGroupMember`, `Remove-JiraGroupMember`,
`Add-JiraIssueWatcher`, `Remove-JiraIssueWatcher`, `Resolve-JiraUser`

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

## Running Tests

**IMPORTANT**: Tests run against the *built* module in `Release/`, not the source files.
You MUST build before testing.

```powershell
# First time setup (install dependencies)
./Tools/setup.ps1

# Build AND test (standard workflow)
Invoke-Build -Task Build, Test

# Or separately:
Invoke-Build -Task Build    # Compiles module into Release/
Invoke-Build -Task Test     # Runs Pester tests against Release/
```

### Available Build Tasks

| Task | What it does |
|------|--------------|
| `Clean` | Removes `Release/` and test artifacts |
| `Build` | Compiles module into `Release/` (includes Clean) |
| `Test` | Runs Pester tests against built module |
| `GenerateExternalHelp` | Generates help XML from `docs/` markdown |

### Common Mistakes

- **Running `Invoke-Pester` directly** — Won't work; tests expect the compiled module
- **Running `Invoke-Build -Task Test` without building** — Tests will fail or use stale code
- **Forgetting `./Tools/setup.ps1`** — Missing dependencies (Pester, InvokeBuild, etc.)

## Review Checklist

When changing PowerShell files:

1. Does the change work on BOTH Cloud and Data Center?
2. If user identity is involved: is `accountId` used for Cloud and `username`/`name` for DC?
3. If text fields are read/written: is ADF conversion conditional on deployment type?
4. Are tests written/updated?
5. Do tests pass? (`Invoke-Build -Task Build && Invoke-Build -Task Test`)
