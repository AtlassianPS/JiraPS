# AI Instructions for JiraPS

> **This file is the single source of truth for AI coding assistants.**
> It is read by GitHub Copilot, Cursor, Claude Code, and other AI tools.
> Tool-specific files (e.g., `CLAUDE.md`, `.cursor/rules/`) reference this file.

## AI Tool Compatibility

This repository supports multiple AI coding tools without vendor lock-in:

| Tool | Entry Point | References |
|------|-------------|------------|
| **GitHub Copilot** | `.github/copilot-instructions.md` | → `AGENTS.md`, `ai-context/` |
| **Cursor** | `.cursor/rules/*.mdc` | → `AGENTS.md`, `ai-context/` |
| **Claude Code** | `CLAUDE.md` | → `AGENTS.md`, `ai-context/` |
| **Any tool** | `AGENTS.md` (this file) | Canonical project rules |

### Directory Structure

```
AGENTS.md                           # Project-level rules (this file)
CLAUDE.md                           # Claude Code entry point
.cursor/rules/jiraps.mdc            # Cursor entry point
.github/
├── copilot-instructions.md         # Copilot entry point
├── ai-context/                     # Shared context (tool-agnostic)
│   └── powershell-rules.md         # PowerShell-specific rules
└── instructions/                   # Copilot file-pattern rules
    └── *.instructions.md           # Applied by file glob
```

### Editing Guidelines

| To change... | Edit this file |
|--------------|----------------|
| Project-wide rules | `AGENTS.md` |
| PowerShell-specific rules | `.github/ai-context/powershell-rules.md` |
| Tool entry points | Only if adding quick-reference summaries |

---

## One Functionality Per Commit

> **RULE**: A commit is a complete, shippable unit of work. It includes the code,
> the tests, and the documentation — all passing. Incomplete work is not committable.

### What "Complete" Means

Every commit must include **all** of the following:

| Component | Required | Location |
|-----------|----------|----------|
| **Code** | The implementation | `JiraPS/Public/` or `JiraPS/Private/` |
| **Unit Tests** | Tests that verify the code works | `Tests/Functions/Public/` or `Tests/Functions/Private/` |
| **Green Tests** | All tests passing | Run `Invoke-Build -Task Build, Test` |
| **Documentation** | Updated docs for user-facing changes | `docs/en-US/commands/*.md`, `CHANGELOG.md` |
| **Linter Clean** | No new PSScriptAnalyzer errors | Run PSScriptAnalyzer |

### Enforcement

- **Do not ask** if the user wants to skip tests or docs — they are part of the functionality
- **Do not commit** until tests are green
- **Do not treat code as "done"** if any component is missing
- If implementing multiple functionalities, make multiple commits — one per functionality

---

## Project Overview

**JiraPS** is a mature PowerShell module (v2.15) that provides a comprehensive interface to interact with Atlassian JIRA via REST API. This is a **legacy codebase** that requires modernization while maintaining backward compatibility for its substantial user base.

-   **Repository**: AtlassianPS/JiraPS
-   **Current Version**: 2.15 (alpha)
-   **PowerShell Compatibility**: PS v3-v5.1, PowerShell Core (6+) on Windows/Ubuntu/macOS
-   **Primary Branch**: `master`
-   **Release Strategy**: Tag-based releases from master branch (push tag `vX.Y.Z` to trigger release)
-   **License**: MIT

## Critical Context

> **JiraPS targets both Jira Cloud AND Data Center.** These have different
> APIs (accountId vs username, ADF vs plain text, different search and
> pagination). Changes must work on both. See
> `.github/ai-context/powershell-rules.md` for detailed rules.

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

> **IMPORTANT**: Tests run against the *built* module in `Release/`, not the source files.
> You MUST build before testing. Running `Invoke-Pester` directly will not work.

**Standard Workflow**:

```powershell
./Tools/setup.ps1              # First time: install dependencies
Invoke-Build -Task Build, Test # Build and test in one command
```

**Build Tasks** (via `Invoke-Build`):

| Task | What it does |
|------|--------------|
| `Clean` | Removes `Release/` and test artifacts |
| `Build` | Compiles module into `Release/` (runs Clean first) |
| `Test` | Runs Pester tests against built module |
| `GenerateExternalHelp` | Generates help XML from `docs/` markdown |
| `Publish` | Publishes to PowerShell Gallery (release tags only) |

**Common Mistakes**:

- ❌ `Invoke-Pester` directly — Tests expect the compiled module in `Release/`
- ❌ `Invoke-Build -Task Test` without building — Uses stale or missing code
- ❌ Forgetting `./Tools/setup.ps1` — Missing Pester, InvokeBuild, etc.
- ✅ `Invoke-Build -Task Build, Test` — Correct: build then test

## API & REST Patterns

### JIRA REST API Version

-   Currently hardcoded to API v2: `/rest/api/2/...`
-   **Known Issue**: Should support dynamic version resolution for Cloud vs. Data Center
-   Atlassian is deprecating some v2 endpoints in favor of v3 **on Cloud only**
-   Data Center retains full v2 support; v3 availability varies by DC release

### Common API Endpoints Used

-   `/rest/api/2/issue/{issueIdOrKey}` - Get/Update issue
-   `/rest/api/2/search` - JQL search (GET with query params, or POST with JSON body)
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
# JIRA uses startAt/maxResults pattern (Data Center and Cloud v2)
Invoke-JiraMethod -URI $uri -Paging
# Automatically handles multiple pages
```

## Jira Cloud vs Data Center Compatibility

> **CRITICAL CONTEXT**: JiraPS targets **both Jira Cloud and Jira Data Center**. These are
> different products with different API behaviors. Any change to API endpoints, request
> bodies, or response handling **must** consider both deployment types. Never assume
> Cloud-only or DC-only usage.

### Two Deployment Types

| Aspect | Jira Cloud | Jira Data Center |
|--------|-----------|------------------|
| API versions | v2 (deprecated) → v3 (current) | v2 (stable), v3 (partial, version-dependent) |
| User identity | `accountId` (GDPR, `username`/`name` removed) | `username` / `name` (traditional) |
| Text fields | Atlassian Document Format (ADF) JSON in v3 | Plain strings or wiki markup |
| Search | `POST /rest/api/3/search/jql` (Cloud migration) | `GET /rest/api/2/search` (stable) |
| Pagination | `nextPageToken` (Cloud search v3) | `startAt` / `maxResults` (offset-based) |
| Rate limiting | Enforced (HTTP 429 + `Retry-After`) | Typically not enforced |
| Session auth | Deprecated | Supported |

### User Identity — The Critical Difference

On **Cloud**, Atlassian removed `username`/`name` fields under GDPR. User operations
require `accountId`:

```powershell
# Cloud v3: use accountId
$resourceUri = "$server/rest/api/3/user?accountId={0}"
$body = @{ assignee = @{ accountId = $user.AccountId } }

# Data Center: use username/name
$resourceUri = "$server/rest/api/2/user?username={0}"
$body = @{ assignee = @{ name = $user.Name } }
```

**Currently affected functions** (still DC-centric, need Cloud paths):
`Get-JiraUser`, `Set-JiraUser`, `Remove-JiraUser`, `New-JiraIssue` (reporter),
`Set-JiraIssue` (assignee), `Invoke-JiraIssueTransition`, `Add-JiraGroupMember`,
`Remove-JiraGroupMember`, `Add-JiraIssueWatcher`, `Remove-JiraIssueWatcher`,
`Resolve-JiraUser`, `ConvertTo-JiraUser.ToString()`

### Atlassian Document Format (ADF)

Cloud v3 returns and expects rich-text fields (`description`, `comment.body`, etc.)
as ADF JSON objects. Data Center returns these as plain strings.

```powershell
# Cloud v3 response for description:
# { "type": "doc", "version": 1, "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Hello" }] }] }

# Data Center response for description:
# "Hello"
```

**Rule**: ADF conversion (`ConvertTo-AtlassianDocumentFormat` / `ConvertFrom-AtlassianDocumentFormat`)
must only be applied when targeting Cloud v3. Sending ADF to Data Center will produce
garbled content or API errors. Reading plain strings through ADF conversion is wasteful
(though the current `ConvertFrom-` function handles strings gracefully as a fallback).

### Search Endpoint

| Deployment | Endpoint | Method | Pagination |
|-----------|----------|--------|------------|
| Cloud v3 | `/rest/api/3/search/jql` | POST (JSON body) | `nextPageToken` |
| Data Center | `/rest/api/2/search` | GET (query params) | `startAt` / `maxResults` |

These are **not interchangeable**. The Cloud endpoint may not exist on DC, and the
paging models are fundamentally different.

### Deployment Type Detection

`Get-JiraServerInformation` returns `deploymentType` from the API (`Cloud` or `Server`).
This is available via `ConvertTo-JiraServerInfo` but **not currently used for branching**.

**Planned approach**: After `Set-JiraConfigServer`, detect and cache the deployment type,
then use it to select the correct API version, user identity model, text format, search
endpoint, and pagination strategy.

### Review Rules for API Changes

When reviewing PRs that modify API endpoints or request/response handling, **always check**:

1. **Deployment awareness**: Does the change work on both Cloud and Data Center?
   If it introduces a Cloud-specific feature (ADF, token paging, `/search/jql`,
   `accountId`), is there a DC fallback?
2. **User identity consistency**: If a URL is changed to v3, are the query params
   and body fields also updated? (`username` → `accountId` for Cloud, keep `username` for DC)
3. **Text field format**: Are description/comment fields being read or written?
   If so, is ADF conversion conditional on deployment type?
4. **Backward compatibility**: Will existing scripts break? The module has users on
   both Cloud and DC — a change that fixes Cloud but breaks DC is not backward compatible.
5. **Test coverage**: Do tests cover both Cloud and DC response shapes?
   Mock data should include both ADF and plain-string variants for text fields.

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
Invoke-Build -Task Build, Test
```

### Updating for API Changes

When JIRA API changes affect a cmdlet:

1. **Determine scope**: Does this affect Cloud only, DC only, or both?
    - Cloud API docs: https://developer.atlassian.com/cloud/jira/platform/rest/v3/
    - DC API docs: https://developer.atlassian.com/server/jira/platform/rest-apis/
2. **Add deployment-type branching** if Cloud and DC behaviors differ
3. **Update endpoint** in the cmdlet's `Invoke-JiraMethod` call
4. **Update user identity** handling if the endpoint involves users (`accountId` for Cloud, `username` for DC)
5. **Update text field handling** if the endpoint reads/writes description, comment, or similar fields (ADF for Cloud v3, plain text for DC)
6. **Update converter** (`ConvertTo-*`) if response schema changed
7. **Update tests** to cover both Cloud and DC response shapes
8. **Update docs** with new parameters/behavior
9. **Add to CHANGELOG.md** under `## [NEXT VERSION]`

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

-   ✅ **Follow "One Functionality Per Commit"** — code + tests + docs + green tests = one commit
-   ✅ Maintain backward compatibility (large user base on **both Cloud and Data Center**)
-   ✅ Follow existing patterns (especially `Invoke-JiraMethod` → `ConvertTo-*`)
-   ✅ Update CHANGELOG.md for user-facing changes
-   ✅ Generate help after adding/modifying cmdlets
-   ✅ Test on both Windows PowerShell 5.1 and PowerShell Core 7+
-   ✅ Use `Write-Verbose` for debugging output
-   ✅ Handle both session-based and credential-based auth
-   ✅ Consider Cloud vs Data Center implications for any API endpoint change
-   ✅ Use `accountId` for Cloud and `username`/`name` for Data Center user operations

### DON'T:

-   ❌ **Commit incomplete functionality** — code without tests/docs is not committable
-   ❌ **Commit with red tests** — all tests must pass before commit
-   ❌ **Ask to skip any part of "One Functionality Per Commit"** — just complete it
-   ❌ Break existing cmdlet interfaces without major version bump
-   ❌ Add runtime dependencies (keep module pure)
-   ❌ Bypass `Invoke-JiraMethod` for REST calls
-   ❌ Hardcode server URLs (use `$script:JiraServerUrl`)
-   ❌ Mix Pester 4 and 5 syntax in same file
-   ❌ Commit Release/ directory (build artifact)
-   ❌ Assume Cloud-only or DC-only usage — always handle both deployment types
-   ❌ Send ADF (Atlassian Document Format) to Data Center instances
-   ❌ Use `username` query params against Cloud v3 endpoints (use `accountId`)

### Common Gotchas

1. **URL Encoding**: Use `ConvertTo-URLEncoded` for query parameters
2. **Custom Fields**: Always use field IDs, not names
3. **Paging**: JIRA API paging is `startAt`/`maxResults`, not skip/take
4. **Session State**: Module stores server config in AppData, may persist between sessions
5. **TLS**: Module explicitly enables TLS 1.2 for older PowerShell versions

## Questions to Ask When Uncertain

1. **Cloud vs DC**: "Does this change work on both Jira Cloud and Data Center?"
2. **API Changes**: "Has this JIRA REST API endpoint changed in recent versions?"
3. **Breaking Changes**: "Will this change break existing user scripts on either deployment type?"
4. **User Identity**: "Am I using accountId for Cloud and username for Data Center?"
5. **Text Format**: "Am I handling both ADF (Cloud) and plain text (DC) for this field?"
6. **Test Coverage**: "Do my tests cover both Cloud and DC response shapes?"
7. **Compatibility**: "Does this work on PowerShell 3.0?"
8. **Authentication**: "Should this cmdlet support both session and credential auth?"

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
# 1. Setup
git checkout master && git pull origin master
git checkout -b feature/my-enhancement
./Tools/setup.ps1

# 2. Implement ONE functionality (code + tests + docs together)
#    - Write/modify code in JiraPS/Public/ or JiraPS/Private/
#    - Write/update tests in Tests/Functions/
#    - Update docs in docs/en-US/commands/ and CHANGELOG.md

# 3. Verify before commit (all must pass)
Invoke-Build -Task Build, Test   # ⛔ Red tests = not committable
Invoke-Build -Task GenerateExternalHelp

# 4. Commit the complete functionality
git add .
git commit -m "Add: Description of change"

# 5. Repeat steps 2-4 for each additional functionality

# 6. Push and create PR
git push origin feature/my-enhancement
```

---

## Summary

JiraPS is a well-established PowerShell module with a large user base. When contributing:

-   Respect existing patterns and backward compatibility
-   Focus on modernizing tests, CI/CD, and deprecated API endpoints
-   Write comprehensive tests and documentation
-   Consider cross-platform and multi-version PowerShell compatibility

This is a legacy codebase requiring careful, incremental improvements rather than aggressive refactoring.
