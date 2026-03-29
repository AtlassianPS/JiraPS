# GitHub Copilot Instructions for JiraPS

## Project Overview

**JiraPS** is a mature PowerShell module (v2.15) that provides a comprehensive interface to interact with Atlassian JIRA via REST API. This is a **legacy codebase** that requires modernization while maintaining backward compatibility for its substantial user base.

-   **Repository**: AtlassianPS/JiraPS
-   **Current Version**: 2.15 (alpha)
-   **PowerShell Compatibility**: PS v3-v5.1, PowerShell Core (6+) on Windows/Ubuntu/macOS
-   **Primary Branch**: `master`
-   **Release Strategy**: Tag-based releases from master branch (push tag `vX.Y.Z` to trigger release)
-   **License**: MIT

## Critical Context

### Known Technical Debt

1. **CI/CD Pipeline**: Currently using older GitHub Actions patterns, needs modernization
2. **Pester Version**: Using Pester 5.7.1, but many tests written for Pester 4.x patterns
3. **JIRA API Changes**: Several APIs have changed over the years; some endpoints may be deprecated or modified
4. **Build System**: Uses InvokeBuild with custom BuildTools module

### Architecture

```
JiraPS/
├── JiraPS/               # Module source
│   ├── Public/           # 58 exported cmdlets (Get-JiraIssue, New-JiraSession, etc.)
│   ├── Private/          # Internal functions (ConvertTo-*, Resolve-*, Invoke-WebRequest wrapper)
│   ├── JiraPS.psm1      # Main module file (loads and exports functions)
│   └── JiraPS.psd1      # Module manifest
├── Tests/               # Pester test suite
│   ├── Functions/
│   │   ├── Public/      # Tests for public CRUD functions
│   │   └── Private/     # Tests for private converter functions
│   └── README.md        # Comprehensive testing guide
├── Tools/               # Build automation
│   ├── BuildTools.psm1
│   └── build.requirements.psd1
├── docs/                # Documentation (Markdown for PlatyPS)
└── JiraPS.build.ps1    # Build script (InvokeBuild)
```

## Module Structure & Patterns

### Core Design Patterns

1. **REST API Wrapper**: All HTTP calls go through `Invoke-JiraMethod` (in Public/)

    - Handles authentication, paging, error resolution, TLS configuration
    - Returns parsed JSON as PSCustomObjects
    - Central point for API changes

2. **Type Conversion**: Private `ConvertTo-*` functions transform API responses

    - `ConvertTo-JiraIssue`: Main issue converter
    - `ConvertTo-JiraUser`, `ConvertTo-JiraProject`, etc.
    - Pattern: Accept `-InputObject`, return custom PSObject with type name

3. **Session Management**:

    - `New-JiraSession`: Creates authenticated session
    - `Set-JiraConfigServer`: Configures server URL (stored in AppData)
    - Supports both session and per-command credentials

4. **Module Loading** (JiraPS.psm1):
    - Dot-sources all Public and Private functions
    - Exports only Public functions
    - Configures default settings ($script:DefaultPageSize, headers, etc.)

### Coding Standards

#### PowerShell Style

-   **Verb-Noun naming**: Follow approved PowerShell verbs (`Get-`, `Set-`, `New-`, `Remove-`, etc.)
-   **PascalCase**: For function names, parameters
-   **Comment-Based Help**: Use `.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`, `.LINK` or external help XML
-   **External Help**: Generated with PlatyPS from Markdown in `docs/en-US/commands/`
-   **Advanced Functions**: Use `[CmdletBinding()]` and parameter validation attributes
-   **Error Handling**: Prefer `-ErrorAction` parameter support and meaningful error messages

#### Parameter Patterns

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

#### Testing Requirements

-   **Test File Location**: Tests are organized by function type:
    -   **Public functions** (CRUD): `Tests/Functions/Public/<FunctionName>.Unit.Tests.ps1`
    -   **Private functions** (Converters): `Tests/Functions/Private/<FunctionName>.Unit.Tests.ps1`
-   **Pester Version**: Tests should work with Pester 5.7+ (v5 syntax)
-   **Test Templates**: Each directory contains a `.template.ps1` file
    -   **Public functions**: `Tests/Functions/Public/.template.ps1` - for API-calling CRUD functions
    -   **Private functions**: `Tests/Functions/Private/.template.ps1` - for data transformation/converter functions
-   **Detailed Guide**: See [`Tests/README.md`](../Tests/README.md) for comprehensive testing documentation including:
    -   Complete test structure examples
    -   Mock debugging techniques
    -   Best practices and common patterns
    -   Context organization guidelines

### Build Process

**Build Tasks** (via `Invoke-Build`):

1. `Clean`: Removes Release/ and test artifacts
2. `Build`: Compiles module into Release/
    - Copies module files
    - Compiles all Private/Public functions into single .psm1
    - Generates external help with PlatyPS
    - Updates manifest with exported functions
3. `Test`: Runs Pester tests on built module
4. `Publish`: Publishes to PowerShell Gallery (on release tags)

**Run Locally**:

```powershell
./Tools/setup.ps1              # Install dependencies
Invoke-Build -Task Build       # Build module
Invoke-Build -Task Test        # Run tests
```

## API & REST Patterns

### JIRA REST API Version

-   Currently hardcoded to API v2: `/rest/api/2/...`
-   **Known Issue**: Should support dynamic version resolution for cloud vs. on-premise
-   Atlassian is deprecating some v2 endpoints in favor of v3

### Common API Endpoints Used

-   `/rest/api/2/issue/{issueIdOrKey}` - Get/Update issue
-   `/rest/api/2/search` - JQL search
-   `/rest/api/2/project` - Project operations
-   `/rest/api/2/user` - User management
-   `/rest/api/2/issue/{issueIdOrKey}/comment` - Comments
-   `/rest/api/2/issue/{issueIdOrKey}/worklog` - Work logs

### Authentication

-   **Basic Auth**: Username + API token (cloud) or password (server)
-   **Session-Based**: Via `New-JiraSession` (creates WebSession)
-   **Anonymous**: Supported for public JIRA instances

### Pagination Pattern

```powershell
# JIRA uses startAt/maxResults pattern
Invoke-JiraMethod -URI $uri -Paging
# Automatically handles multiple pages
```

## Common Tasks & Solutions

### Adding a New Cmdlet

1. **Create function file**: `JiraPS/Public/Verb-JiraNoun.ps1`
2. **Write tests**: `Tests/Functions/Public/Verb-JiraNoun.Unit.Tests.ps1` (use [`.template.ps1`](../Tests/Functions/Public/.template.ps1))
3. **Write documentation**: `docs/en-US/commands/Verb-JiraNoun.md`
4. **Pattern to follow**:

```powershell
function Get-JiraExample {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]$Id,

        [PSCredential]$Credential
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        $parameter = @{
            URI    = "$($script:JiraServerUrl)/rest/api/2/example/$Id"
            Method = "GET"
        }
        if ($Credential) {
            $parameter["Credential"] = $Credential
        }

        $result = Invoke-JiraMethod @parameter
        ConvertTo-JiraExample -InputObject $result
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
```

5. **Build and test**:

```powershell
Invoke-Build -Task Build
Invoke-Build -Task Test
```

### Updating for API Changes

When JIRA API changes affect a cmdlet:

1. **Check JIRA API docs**: https://developer.atlassian.com/cloud/jira/platform/rest/v3/
2. **Update endpoint** in the cmdlet's `Invoke-JiraMethod` call
3. **Update converter** (`ConvertTo-*`) if response schema changed
4. **Update tests** to reflect new API responses
5. **Update docs** with new parameters/behavior
6. **Add to CHANGELOG.md** under `## [NEXT VERSION]`

### Test Template Reference

JiraPS uses two primary test templates based on function type. **For comprehensive details, see [`Tests/README.md`](../Tests/README.md)**.

#### Public CRUD Functions

**Location**: `Tests/Functions/Public/`
**Template**: [`Tests/Functions/Public/.template.ps1`](../Tests/Functions/Public/.template.ps1)
**Reference**: [`Add-JiraFilterPermission.Unit.Tests.ps1`](../Tests/Functions/Public/Add-JiraFilterPermission.Unit.Tests.ps1)
**Use For**: Get-_, Set-_, New-_, Remove-_, Add-\* functions that make API calls

**Key Characteristics**: Three Describe blocks (Signature, Behavior, Input Validation), extensive mocking, API interaction focus

#### Private Converter Functions

**Location**: `Tests/Functions/Private/`
**Template**: [`Tests/Functions/Private/.template.ps1`](../Tests/Functions/Private/.template.ps1)
**Reference**: [`ConvertTo-JiraAttachment.Unit.Tests.ps1`](../Tests/Functions/Private/ConvertTo-JiraAttachment.Unit.Tests.ps1)
**Use For**: ConvertTo-_, ConvertFrom-_ functions that transform data

**Key Characteristics**: Single Describe block with four contexts (Object Conversion, Property Mapping, Type Conversion, Pipeline Support), large JSON fixtures, minimal mocking

### Mock Debugging

Enable mock parameter debugging in tests:

```powershell
BeforeAll {
    . "$PSScriptRoot/../Helpers/Write-MockDebugInfo.ps1"
    $VerbosePreference = 'Continue'  # Uncomment to see mock debug output

    Mock Invoke-JiraMethod -ModuleName JiraPS {
        Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
        # mock implementation
    }
}
```

Output format:

```
🔷 Mock: Invoke-JiraMethod
  [Method] = "GET"
  [Uri] = "https://jira.example.com/rest/api/2/issue/TEST-123"
  [Body] = <null>
```

**Note**: The `-Verbose` parameter on `Invoke-Pester` does NOT enable mock debugging. You must set `$VerbosePreference = 'Continue'` inside the test file's BeforeAll block.

### Working with Custom Fields

JIRA custom fields have IDs like `customfield_10001`:

```powershell
# Set custom field in New-JiraIssue or Set-JiraIssue
$fields = @{
    customfield_10001 = "Value"
}
New-JiraIssue -Fields $fields ...
```

## CI/CD & Workflows

### Current Workflows

1. **build_and_test.yml**: Runs on PR/push to master

    - Builds on Ubuntu
    - Tests on Windows (PS5.1 + PS7) and Ubuntu
    - Uses artifact upload/download pattern

2. **release.yml**: Runs on version tags (`v*`)
    - Downloads build artifact from tagged commit
    - Runs `Invoke-Build -Task Publish`
    - Creates GitHub release with CHANGELOG excerpt

### Improvement Opportunities

-   Modernize to newer action versions (v4 → v5)
-   Add PSScriptAnalyzer to PR checks
-   Add test coverage reporting
-   Consider matrix testing for multiple PowerShell versions

## Dependencies

**Runtime**: None (pure PowerShell)

**Build-time** (in `Tools/build.requirements.psd1`):

-   InvokeBuild 5.13.1 - Build automation
-   BuildHelpers 2.0.16 - Environment detection
-   Metadata 1.5.7 - Manifest manipulation
-   Pester 5.7.1 - Testing framework
-   platyPS 0.14.2 - Help generation
-   PSScriptAnalyzer 1.24.0 - Code analysis

## Documentation

### Help System

-   **Markdown source**: `docs/en-US/commands/*.md`
-   **Generated XML**: `JiraPS/en-US/JiraPS-help.xml` (via PlatyPS)
-   **About topics**: `docs/en-US/about_*.md` → compiled to `JiraPS/en-US/*.help.txt`

### External Links

-   **Project Site**: https://atlassianps.org/docs/JiraPS/
-   **PowerShell Gallery**: https://www.powershellgallery.com/packages/JiraPS
-   **Slack**: atlassianps.slack.com

## When Working on This Project

### DO:

-   ✅ Maintain backward compatibility (large user base)
-   ✅ Follow existing patterns (especially `Invoke-JiraMethod` → `ConvertTo-*`)
-   ✅ Write/update unit tests with Pester 5 syntax
-   ✅ Update CHANGELOG.md for user-facing changes
-   ✅ Generate help after adding/modifying cmdlets
-   ✅ Test on both Windows PowerShell 5.1 and PowerShell Core 7+
-   ✅ Use `Write-Verbose` for debugging output
-   ✅ Handle both session-based and credential-based auth

### DON'T:

-   ❌ Break existing cmdlet interfaces without major version bump
-   ❌ Add runtime dependencies (keep module pure)
-   ❌ Bypass `Invoke-JiraMethod` for REST calls
-   ❌ Hardcode server URLs (use `$script:JiraServerUrl`)
-   ❌ Forget to update documentation in `docs/`
-   ❌ Mix Pester 4 and 5 syntax in same file
-   ❌ Commit Release/ directory (build artifact)

### Common Gotchas

1. **URL Encoding**: Use `ConvertTo-URLEncoded` for query parameters
2. **Custom Fields**: Always use field IDs, not names
3. **Paging**: JIRA API paging is `startAt`/`maxResults`, not skip/take
4. **Session State**: Module stores server config in AppData, may persist between sessions
5. **TLS**: Module explicitly enables TLS 1.2 for older PowerShell versions

## Questions to Ask When Uncertain

1. **API Changes**: "Has this JIRA REST API endpoint changed in recent versions?"
2. **Breaking Changes**: "Will this change break existing user scripts?"
3. **Test Coverage**: "What edge cases should I test for this parameter?"
4. **Compatibility**: "Does this work on PowerShell 3.0?"
5. **Authentication**: "Should this cmdlet support both session and credential auth?"

## Module-Specific Patterns to Follow

### Error Handling

```powershell
try {
    $result = Invoke-JiraMethod @params
} catch {
    $PSCmdlet.ThrowTerminatingError($_)
}
```

### Parameter Validation

```powershell
# Use validation attributes
[ValidateNotNullOrEmpty()]
[ValidatePattern('^\w+-\d+$')]  # For issue keys like "PROJ-123"
[ValidateScript({ Test-Path $_ })]
```

### Pipeline Support

```powershell
[Parameter(ValueFromPipeline)]
[Object[]]$InputObject

process {
    foreach ($item in $InputObject) {
        # Process each item
    }
}
```

### Type Names for Formatting

```powershell
$result.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
# Enables custom formatting via JiraPS.format.ps1xml
```

## Priorities for Modernization

1. **High Priority**:

    - Migrate remaining Pester 4 tests to Pester 5 syntax
    - Update deprecated JIRA API endpoints (check createMeta, search, etc.)

2. **Medium Priority**:

    - Upgrade GitHub Actions to latest versions
    - Add PSScriptAnalyzer enforcement to CI
    - Support JIRA API v3 where applicable
    - Improve error messages with API response details

3. **Low Priority**:
    - Consider async/parallel operations for bulk actions
    - Refactor session management for better multi-server support
    - Add integration tests (currently only unit tests)
    - Performance optimization for large result sets

## Example Contribution Workflow

```powershell
# 1. Checkout and branch
git checkout master
git pull origin master
git checkout -b feature/my-enhancement

# 2. Install dependencies
./Tools/setup.ps1

# 3. Make changes to JiraPS/Public/*.ps1 or Private/*.ps1

# 4. Update tests in Tests/Functions/*.Unit.Tests.ps1

# 5. Build and test
Invoke-Build -Task Build
Invoke-Build -Task Test

# 6. Update documentation if needed
# Edit docs/en-US/commands/*.md
Invoke-Build -Task GenerateExternalHelp

# 7. Update CHANGELOG.md under [NEXT VERSION]

# 8. Commit and push
git add .
git commit -m "Add: Description of change"
git push origin feature/my-enhancement

# 9. Create PR to master branch
```

---

## Summary

JiraPS is a well-established PowerShell module with a large user base. When contributing:

-   Respect existing patterns and backward compatibility
-   Focus on modernizing tests, CI/CD, and deprecated API endpoints
-   Write comprehensive tests and documentation
-   Consider cross-platform and multi-version PowerShell compatibility

This is a legacy codebase requiring careful, incremental improvements rather than aggressive refactoring.
