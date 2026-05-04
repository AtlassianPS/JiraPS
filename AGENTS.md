# AI Instructions for JiraPS

> **Single source of truth for AI coding assistants.** Tool-specific files reference this.

## Quick Reference (Critical Rules)

<!-- NOTE: Copilot PR Review reads only first 4,000 chars. Keep critical rules here. -->

### Commit Rules
- **One Functionality Per Commit** — code + tests + docs + green tests = one commit
- **Do not commit** until `Invoke-Build -Task Build, Test` passes
- **Do not skip** tests or docs — they are part of the functionality

### Cloud vs Data Center
- **All changes must work on BOTH** Jira Cloud and Data Center
- **User identity**: `accountId` for Cloud, `username`/`name` for DC
- **Text fields**: ADF JSON for Cloud v3, plain strings for DC
- See [powershell-rules.md](.github/ai-context/powershell-rules.md) for details

### Code Comments
- Comments are the **last resort** — code is the primary documentation
- **DO comment**: Non-obvious constraints, API quirks, design decisions
- **DO NOT comment**: What code does, obvious operations, changes being made
- Use `#ToDo:Category` format for TODOs (e.g., `#ToDo:Deprecate`, `#ToDo:CustomClass`)
- Remove dead code — don't comment it out

### File Locations
| Type | Location |
|------|----------|
| Public functions | `JiraPS/Public/` |
| Private functions | `JiraPS/Private/` |
| Tests | `Tests/Functions/Public/` or `Tests/Functions/Private/` |
| Docs | `docs/en-US/commands/` |

### Build & Test
```powershell
./Tools/setup.ps1
Invoke-Build -Task Build, Test
```
Tests run against the built module in `Release/` — you must build before testing.

### Backlog Handling
- **Out-of-scope ideas go on the board, not into the current PR.**
  File them as `Backlog idea` issues — see [Filing a Backlog Idea](#filing-a-backlog-idea).
- Board: [`AtlassianPS/JiraPS` · Project 2 — *JiraPS Backlog*](https://github.com/orgs/AtlassianPS/projects/2)

---

## AI Tool Compatibility

This repository supports multiple AI coding tools without vendor lock-in:

| Tool | Entry Point | References |
|------|-------------|------------|
| **GitHub Copilot** | `.github/copilot-instructions.md` | → `AGENTS.md`, `ai-context/` |
| **Cursor** | `.cursor/rules/*.mdc` | → `AGENTS.md`, `ai-context/` |
| **Claude Code/CLI** | `CLAUDE.md` | → `AGENTS.md`, `ai-context/` |
| **Antigravity** | `GEMINI.md` | → `AGENTS.md`, `ai-context/` |
| **Any tool** | `AGENTS.md` (this file) | Canonical project rules |

### Directory Structure

```
AGENTS.md                           # Project-level rules (this file)
CLAUDE.md                           # Claude Code entry point
GEMINI.md                           # Antigravity entry point
.cursor/rules/jiraps.mdc            # Cursor entry point
.github/
├── copilot-instructions.md         # Copilot Chat entry point
├── ai-context/                     # Shared context (tool-agnostic)
│   ├── powershell-rules.md         # PowerShell + Cloud/DC rules
│   └── releasing.md                # Release procedure
└── instructions/                   # Copilot file-pattern rules
    └── *.instructions.md
```

### Editing Guidelines

| To change... | Edit |
|--------------|------|
| Project-wide rules | `AGENTS.md` (this file) |
| PowerShell-specific rules | `.github/ai-context/powershell-rules.md` |
| Release procedure | `.github/ai-context/releasing.md` |
| Quick Reference (Critical Rules) | `AGENTS.md` **and** all four entry-point files (`CLAUDE.md`, `GEMINI.md`, `.cursor/rules/jiraps.mdc`, `.github/copilot-instructions.md`) — keep them in sync |

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

**JiraPS** is a mature PowerShell module that provides a comprehensive interface to interact with Atlassian JIRA via REST API. This is a **legacy codebase** that requires modernization while maintaining backward compatibility for its substantial user base.

-   **Repository**: AtlassianPS/JiraPS
-   **Current Version**: see [`JiraPS/JiraPS.psd1`](JiraPS/JiraPS.psd1) (`ModuleVersion`)
-   **PowerShell Compatibility**: PS v5.1, PowerShell Core (6+) on Windows/Ubuntu/macOS
-   **Primary Branch**: `master`
-   **Release Strategy**: Tag-based releases from master branch (push tag `vX.Y.Z` to trigger release)
-   **License**: MIT

## Known Technical Debt

1. **Pester syntax mix**: Tests target Pester 5, but many files retain Pester 4 patterns
2. **API version drift**: Some Cloud endpoints have been deprecated in favor of v3
3. **Build system**: Uses InvokeBuild with custom BuildTools module — non-standard layout

## Architecture

```
JiraPS/                  # Module source (Public/ exports cmdlets, Private/ holds ConvertTo-*/Resolve-*)
Tests/                   # Pester suite — Functions/Public, Functions/Private (unit), Integration/ (live API)
Tools/                   # InvokeBuild scripts + build.requirements.psd1
docs/                    # PlatyPS markdown sources for external help
JiraPS.build.ps1         # InvokeBuild entry point
.env.example             # Template for integration-test credentials (real .env is gitignored)
Release/                 # Build output (gitignored)
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
    - Pattern: Accept `-InputObject`, emit `[AtlassianPS.JiraPS.*]` instances (hashtable cast, with `ConvertTo-Hashtable` when the input is a `PSCustomObject` on Windows PowerShell 5.1)

3. **Session Management**:

    - `New-JiraSession`: Creates authenticated session
    - `Set-JiraConfigServer`: Configures server URL (stored in AppData)
    - Supports both session and per-command credentials

4. **Module Loading** (JiraPS.psm1):
    - Dot-sources all Public and Private functions
    - Exports only Public functions
    - Configures default settings ($script:DefaultPageSize, headers, etc.)

5. **Strong types (`AtlassianPS.JiraPS.*`)**:
    - POCOs live in `JiraPS/Types/AtlassianPS.JiraPS.cs` and compile at first import via `Add-Type` in `JiraPS.psm1` (`#region Dependencies`). See **Compiled types at import** in `CHANGELOG.md` (`[Unreleased]`) for cold-start, host, and C# language constraints.
    - `ConvertTo-Jira*` functions build a hashtable (or launder a wire `PSCustomObject` through `ConvertTo-Hashtable` on Windows PowerShell 5.1), then cast to the target class.

### Argument transformation attributes

`ArgumentTransformationAttribute` subclasses in `AtlassianPS.JiraPS.cs` coerce issue keys, user identifiers, and similar inputs at parameter binding time.

**Throw vs. pass-through (parameter-set fallthrough)**

- Use **`return inputData` unchanged** (do not throw) when the parameter participates in **competing `ValueFromPipeline` parameter sets** and the piped value might legitimately bind to a **different** set. Throwing `ArgumentTransformationMetadataException` blocks the binder from trying the alternate set. Example: `Get-JiraVersion` pipes either a `Version` (`-InputVersion`) or a `Project` (`-InputProject`) — `VersionTransformationAttribute` therefore returns unrecognized input untouched so fallthrough can occur.
- Use **throw** with an actionable `ArgumentTransformationMetadataException` when there is **no** such alternate set, so callers get a clear error instead of a generic coercion failure.

When you add a new `*TransformationAttribute`, decide which rule applies before copying an existing implementation.

### Coding Standards

#### PowerShell Style

-   **Verb-Noun naming**: Follow approved PowerShell verbs (`Get-`, `Set-`, `New-`, `Remove-`, etc.)
-   **PascalCase**: For function names, parameters
-   **Naming as documentation**: Variables are nouns (`$issue`, `$filter`), functions are verbs (`Get-JiraIssue`). Names should be self-explanatory — avoid abbreviations unless universally understood.
-   **External Help Only**: Public functions use PlatyPS-generated external help (Markdown sources in `docs/en-US/commands/`). Do **not** add comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`, `.PARAMETER`, `.LINK`, etc.) to files in `JiraPS/Public/`. Public function files contain a single `# .ExternalHelp ..\JiraPS-help.xml` directive at the top of the function body — nothing more.
-   **No Parameter Comments**: Do **not** add descriptive comments above or beside parameters in public functions. Parameter documentation lives in `docs/en-US/commands/*.md` and is rendered by PlatyPS. The only allowed inline comments on parameters are `#ToDo:Category` markers (with their context block) for tracked technical debt.
-   **Advanced Functions**: Use `[CmdletBinding()]` and parameter validation attributes
-   **Error Handling**: Prefer `-ErrorAction` parameter support and meaningful error messages

#### Parameter Patterns

See [`powershell-rules.md` → Parameter Patterns](.github/ai-context/powershell-rules.md#parameter-patterns) for the canonical `[CmdletBinding()]` + `[Parameter]` + `[PSCredential]` template.

#### Code Comments

Follow the "code is documentation" principle. Comments are the **last resort** when naming, structure, and context cannot convey intent.

**DO comment:**

-   Non-obvious constraints or edge cases (API quirks, workarounds)
-   Design decisions that would otherwise be unclear
-   TODO items with specific context (`#ToDo:Category` format)
-   Suppression attributes with justification

**DO NOT comment:**

-   What the code does (the code shows that)
-   Obvious operations ("increment counter", "loop through items", "call the API")
-   Function purpose if the name is already clear
-   Changes being made (that's what commit messages are for)

**Examples:**

```powershell
# GOOD - Explains a non-obvious API constraint
# JIRA returns 500 if visibility block is passed with "All Users"
if ($VisibleRole -ne 'All Users') {
    $body.visibility = @{ type = $VisibleRole }
}

# GOOD - Specific TODO with context and category
#ToDo:Deprecate
# This parameter check is redundant once $Key uses ValueFromPipelineByPropertyName
if (-not $Key -and $InputObject) {
    $Key = $InputObject.Key
}

# BAD - Narrates what code does (the code already shows this)
$result = Invoke-JiraMethod @params  # Call the API
foreach ($item in $items) {          # Loop through items
    $count++                         # Increment counter
}

# BAD - Vague TODO without actionable context
#ToDo: fix this later
```

**Runtime documentation:** Use `Write-Verbose` and `Write-Debug` for operational insight instead of inline comments.

**Help documentation (public functions):** All cmdlet help — synopsis, description, examples, parameter descriptions, links — lives in `docs/en-US/commands/*.md` and is compiled by PlatyPS into the external help XML. Files in `JiraPS/Public/` MUST NOT contain:

-   Comment-based help blocks (`<# .SYNOPSIS ... #>`, `.DESCRIPTION`, `.EXAMPLE`, `.PARAMETER`, `.LINK`, `.NOTES`, `.INPUTS`, `.OUTPUTS`)
-   Descriptive comments above or beside parameter declarations
-   Doc-style banners or summaries above the `function` keyword

The only header line in a public function is the `# .ExternalHelp ..\JiraPS-help.xml` directive that wires the function to the generated XML help. If a parameter needs better documentation, update its entry in `docs/en-US/commands/<FunctionName>.md`, not the source file.

Private functions in `JiraPS/Private/` may use minimal comment-based help (`.SYNOPSIS` only) when truly helpful, but prefer self-describing names.

**TODO format:** Use `#ToDo:Category` with a descriptive comment on the next line:

| Category | When to use |
|----------|-------------|
| `#ToDo:CustomClass` | Placeholder for future type system improvements |
| `#ToDo:Deprecate` | Code to be removed in a future version |
| `#ToDo:Implement` | Feature not yet implemented |
| `#ToDo:Refactor` | Code that works but needs cleanup |

**Region markers:** Use `#region`/`#endregion` sparingly — only in complex functions with multiple logical sections (like `Invoke-JiraMethod`). Do not use regions to hide code that should be refactored into separate functions.

**Rule suppression:** When suppressing PSScriptAnalyzer rules, always include a justification:

```powershell
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    "PSAvoidUsingConvertToSecureStringWithPlainText",
    "",
    Justification = "Converting received plaintext token to SecureString"
)]
```

**Commented-out code:** Remove dead code instead of commenting it out. Version control preserves history. Commented-out code creates confusion about whether it's intentional, temporary, or forgotten.

#### Testing Requirements

-   **Test File Location**: Tests are organized by type:
    -   **Public functions** (CRUD): `Tests/Functions/Public/<FunctionName>.Unit.Tests.ps1`
    -   **Private functions** (Converters): `Tests/Functions/Private/<FunctionName>.Unit.Tests.ps1`
    -   **Integration** (live Jira Cloud): `Tests/Integration/<Feature>.Integration.Tests.ps1`
-   **Pester Version**: Use Pester 5 syntax (v5 is required; v4 patterns must be migrated)
-   **Test Templates**: Each directory has a `.template.ps1` to copy from
-   **Unit test guide**: [`Tests/README.md`](Tests/README.md) — structure, mocks, debugging, conventions
-   **Integration test guide**: [`Tests/Integration/README.md`](Tests/Integration/README.md) — credentials setup, fixtures, parallel execution, CI behavior

### Build Process

> **IMPORTANT**: Unit tests run against the *built* module in `Release/`, not the source files.
> You MUST build before running unit tests.
>
> Integration tests run directly against `JiraPS/JiraPS.psd1` (no build step) and require live Jira Cloud credentials.
> macOS and Linux contributors cannot execute the Windows PowerShell 5.1 lane locally, so treat that CI lane as a required pre-merge gate.

```powershell
./Tools/setup.ps1
Invoke-Build -Task Build, Test                       # Unit tests (excludes Integration)
Invoke-Build -Task TestIntegration                   # Integration tests (needs .env)
Invoke-Build -Task TestIntegration -Tag 'Smoke'      # Smoke subset only
```

The integration suite has two tracks:

- **Cloud** (default) — runs against a live Atlassian Cloud instance via `JIRA_CLOUD_*` secrets.
- **Server** — runs against a Dockerized Jira Data Center (`moveworkforward/atlas-run-standalone:jira-11`); no secrets needed. Switch tracks by setting `CI_JIRA_TYPE=Server` and filtering with `-Tag 'Server'`.

See [`Tests/Integration/README.md`](Tests/Integration/README.md) for the local quickstart and full track guide.

The `Publish` task (PowerShell Gallery upload) is reserved for release tags.

See [`powershell-rules.md` → Running Tests](.github/ai-context/powershell-rules.md#running-tests) for the full task list and common mistakes.

### Testing During Development

> **RULE**: Run the appropriate tests after every change. Do not wait until the end.

| What you changed | Test command |
|------------------|--------------|
| **Any code file** (`.ps1`, `.psm1`) | `Invoke-Build -Task Lint` |
| **Function** in `JiraPS/Public/` | `Invoke-Pester Tests/Functions/Public/<FunctionName>.Unit.Tests.ps1` |
| **Function** in `JiraPS/Private/` | `Invoke-Pester Tests/Functions/Private/<FunctionName>.Unit.Tests.ps1` |
| **Test file** in `Tests/` | `Invoke-Pester <path-to-that-test-file>` |
| **Documentation** in `docs/**` | `Invoke-Pester Tests/Help.Tests.ps1` |

**Examples:**

```powershell
# After editing JiraPS/Public/Get-JiraIssue.ps1
Invoke-Build -Task Lint
Invoke-Pester Tests/Functions/Public/Get-JiraIssue.Unit.Tests.ps1

# After editing docs/en-US/commands/Get-JiraIssue.md
Invoke-Build -Task Lint
Invoke-Pester Tests/Help.Tests.ps1

# After editing a test file
Invoke-Build -Task Lint
Invoke-Pester Tests/Functions/Public/Get-JiraIssue.Unit.Tests.ps1
```

**Why localized tests?**
- Faster feedback loop — no need to build the entire module for linting or docs
- `Invoke-Build -Task Lint` runs PSScriptAnalyzer to catch code issues early
- `Style.Tests.ps1` (encoding, whitespace, line endings) runs with the full test suite

**Before committing**: Run full `Invoke-Build -Task Build, Test`.
**Before merging**: Ensure the Windows PowerShell 5.1 `Test` job in `ci.yml` is green.

**VSCode Integration:**

- The `pspester.pester-test` extension provides Code Lens "Run Test" above `It` blocks
- PSScriptAnalyzer warnings appear in real-time via `powershell.scriptAnalysis.settingsPath`
- Format on save uses Stroustrup style (`powershell.codeFormatting.preset`)

**CI Pipeline (runs on PR):**

1. **Lint** — PSScriptAnalyzer + style checks (fail-fast gate)
2. **Build** — Compiles module to `Release/`
3. **Test** — Unit tests on Windows PS5, Windows PS7, Ubuntu, macOS

CI skips for docs-only changes (`README.md`, `CHANGELOG.md`, `AGENTS.md`, `.cursor/**`, etc.).

## API & REST Patterns

- **All HTTP calls** go through `Invoke-JiraMethod` — never call `Invoke-RestMethod` / `Invoke-WebRequest` directly
- **Endpoint selection** (v2 vs v3, Cloud vs DC): see [`powershell-rules.md`](.github/ai-context/powershell-rules.md)
- **Pagination**: pass `-Paging` to `Invoke-JiraMethod` for `startAt`/`maxResults` flows; Cloud v3 search uses `nextPageToken` internally
- **Authentication**: Basic auth (token on Cloud, password on DC), session-based via `New-JiraSession`, or anonymous

## Common Tasks & Solutions

### Adding a New Cmdlet

1. **Create function file**: `JiraPS/Public/Verb-JiraNoun.ps1`
2. **Write tests**: `Tests/Functions/Public/Verb-JiraNoun.Unit.Tests.ps1` (use [`.template.ps1`](Tests/Functions/Public/.template.ps1))
3. **Write documentation**: `docs/en-US/commands/Verb-JiraNoun.md`
4. **Update `CHANGELOG.md`** under the next-version section
5. **Pattern to follow** (parameter declarations follow [`powershell-rules.md` → Parameter Patterns](.github/ai-context/powershell-rules.md#parameter-patterns)):

```powershell
function Get-JiraExample {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Id,

        [PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        $parameter = @{
            URI        = "$($script:JiraServerUrl)/rest/api/2/example/$Id"
            Method     = "GET"
            Credential = $Credential
        }

        $result = Invoke-JiraMethod @parameter
        ConvertTo-JiraExample -InputObject $result
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
```

6. **Build and test**: `Invoke-Build -Task Build, Test`

### Filing a Backlog Idea

> **RULE**: When a chat, code review, or audit produces a follow-up that does not belong in the current PR, file it as a `Backlog idea` issue **before** the conversation ends.
> Worktrees and chat transcripts are not durable backlog storage.

The repository ships a dedicated GitHub issue form (`.github/ISSUE_TEMPLATE/backlog-idea.yml`) and a repo-scoped GitHub Project board for triage.
The form auto-applies the `Backlog` label and adds the issue to the project on submit, so the only manual triage step is setting `Theme`, `Effort`, and `Priority` on the board.

| Where | What |
|-------|------|
| Issue template | `.github/ISSUE_TEMPLATE/backlog-idea.yml` (Context / Proposal / Trade-offs / Related items) |
| Label | `Backlog` (applied automatically by the template) |
| Theme labels | `Theme:TypeSystem` (more added as themes emerge) |
| Project board | [AtlassianPS · Project 2 — *JiraPS Backlog*](https://github.com/orgs/AtlassianPS/projects/2) — custom fields: `Theme`, `Effort` (S/M/L/XL), `Priority` (P0–P3) |

**File via UI:**

1. Open *New issue* on `AtlassianPS/JiraPS` → choose **Backlog idea**.
2. Fill in *Context*, *Proposal*, *Trade-offs* (optional), *Related items* (optional).
3. Submit.
   The `Backlog` label and the project board entry are applied automatically; pick `Theme`, `Effort`, and `Priority` on the board.

**File via CLI** (one-shot, from any worktree):

```bash
gh issue create \
    --repo AtlassianPS/JiraPS \
    --title "[Backlog] <one-line summary>" \
    --label Backlog \
    --body "$(cat <<'EOF'
## Context
…

## Proposal
…

## Trade-offs
…

## Related items
…
EOF
)"

# Then attach to the project board:
gh project item-add 2 --owner AtlassianPS --url <issue-url>
```

When linking an idea that came out of a chat, paste the transcript link into *Related items* so the design rationale is one click away.

### Releasing a New Version

See [`.github/ai-context/releasing.md`](.github/ai-context/releasing.md) for the full release process.

**Quick reference** (substitute `X.Y` with the next version):

1. Update `CHANGELOG.md` (header: `## X.Y - YYYY-MM-DD`, no `v` prefix)
2. Update `JiraPS/JiraPS.psd1` (`ModuleVersion`)
3. Run `Invoke-Build -Task Build, Test`
4. Commit: `git commit -m "Release vX.Y"`
5. Tag and push: `git tag -a vX.Y -m "Release vX.Y" && git push origin master --tags`

### Updating for API Changes

Follow the [`powershell-rules.md` Review Checklist](.github/ai-context/powershell-rules.md#review-checklist). The full set of side effects (converter updates, response-shape tests, docs, CHANGELOG) is governed by the [One Functionality Per Commit](#one-functionality-per-commit) rule.

**API references**:
- Cloud: https://developer.atlassian.com/cloud/jira/platform/rest/v3/
- Data Center: https://developer.atlassian.com/server/jira/platform/rest-apis/

## CI/CD & Workflows

- `ci.yml` — runs on PR/push to `master`; pipeline is **Lint → Build → Test** + **Smoke** (Cloud `Smoke`-tagged subset). Lint = PSScriptAnalyzer + style checks (Ubuntu). Build compiles to `Release/` (Ubuntu). Test runs against the artifact on Windows PS 5.1, Windows PS 7, Ubuntu, and macOS. Smoke runs in parallel after lint, against Jira Cloud; it skips (without failing the gate) on fork / Dependabot PRs where secrets are unavailable. A `CI Result` sentinel job aggregates the pipeline result — branch protection should require **only that** check, and `release.yml` consumes the same aggregator via `workflow_conclusion: success`, so a smoke failure also blocks releases.
- `integration_tests.yml` — two parallel jobs that share a nightly cron (`0 5 * * *`) + manual `workflow_dispatch` (with an optional `track` input to dispatch one or both):
  - `cloud_integration_tests` — full Cloud suite. Per-PR Cloud coverage is the Smoke job in `ci.yml`. The `TestIntegration` build task validates required env vars and fails early if any are missing.
  - `server_integration_tests` — `Server`-tagged suite against a Dockerized Jira Data Center (`moveworkforward/atlas-run-standalone:jira-11`). **Never wired up to PRs**: the cold-boot cost (~25 min) is too expensive for per-PR feedback; PR-level Server coverage comes from the Server-tagged unit suites in `ci.yml`. Use `gh workflow run "Integration Tests" --ref <branch> -f track=server` to trigger on demand when working on a Server-track change.
- `release.yml` — runs on `v*` tags, downloads the `Release` artifact produced by `ci.yml` for the tagged commit, publishes to PSGallery, and creates a GitHub Release.
- Workflow source: [`.github/workflows/`](.github/workflows/); shared setup: [`.github/actions/setup-powershell/`](.github/actions/setup-powershell/) (caller must run `actions/checkout` first).
- CI triage runbook: [`.github/ai-context/ci-triage-runbook.md`](.github/ai-context/ci-triage-runbook.md).

## Dependencies

**Runtime**: None (pure PowerShell)

**Build-time**: Pinned in [`Tools/build.requirements.psd1`](Tools/build.requirements.psd1) — InvokeBuild, Metadata, Pester, PlatyPS, PSScriptAnalyzer.

## Documentation

- **Per-cmdlet help**: edit `docs/en-US/commands/*.md` (PlatyPS source); XML help is generated by `Invoke-Build -Task GenerateExternalHelp`
- **About topics**: `docs/en-US/about_*.md` → compiled to `JiraPS/en-US/*.help.txt`
- **Project site**: https://atlassianps.org/docs/JiraPS/ · **Gallery**: https://www.powershellgallery.com/packages/JiraPS

### Markdown Style

- **One sentence per line** in every markdown file in this repository.
  This includes `CHANGELOG.md`, `README.md`, `AGENTS.md`, `.github/**/*.md`, **and** `docs/en-US/commands/*.md` and `docs/en-US/about_*.md`.
  The PlatyPS sources were bootstrapped once and are now hand-maintained — the build only reads them, it never rewrites them.
  Long single-line paragraphs make code review and `git blame` painful.
  Inside a list item, indent continuation lines two spaces so they stay part of the same bullet.
- **Soft line breaks render as a single space** in both kramdown (the Jekyll site) and Markdig (PlatyPS' parser), so reflowing a prose paragraph to one sentence per line does not change `Get-Help` or website output.
- **Do not break fenced code blocks or YAML frontmatter** — line breaks are significant inside ```` ``` ```` fences and YAML, so leave example code, parameter metadata blocks, and frontmatter as-is.

## When Working on This Project

> Cloud/DC rules live in the [Quick Reference](#quick-reference-critical-rules) and
> [`powershell-rules.md`](.github/ai-context/powershell-rules.md) — they are not repeated here.

### DO:

-   ✅ **Follow "One Functionality Per Commit"** — code + tests + docs + green tests = one commit
-   ✅ Maintain backward compatibility (large user base across both deployment types)
-   ✅ Follow existing patterns (especially `Invoke-JiraMethod` → `ConvertTo-*`)
-   ✅ Update CHANGELOG.md for user-facing changes
-   ✅ Generate help after adding/modifying cmdlets
-   ✅ Test on both Windows PowerShell 5.1 and PowerShell Core 7+
-   ✅ Use `Write-Verbose` for debugging output
-   ✅ Handle both session-based and credential-based auth

### DON'T:

-   ❌ **Commit incomplete functionality** — code without tests/docs is not committable
-   ❌ **Commit with red tests** — all tests must pass before commit
-   ❌ **Ask to skip any part of "One Functionality Per Commit"** — just complete it
-   ❌ Break existing cmdlet interfaces without major version bump
-   ❌ Add runtime dependencies (keep module pure)
-   ❌ Bypass `Invoke-JiraMethod` for REST calls
-   ❌ Hardcode server URLs (use `$script:JiraServerUrl`)
-   ❌ Mix Pester 4 and 5 syntax in same file
-   ❌ Commit `Release/` directory (build artifact)

### Common Gotchas

1. **URL Encoding**: Use `ConvertTo-URLEncoded` for query parameters
2. **Custom Fields**: Always use field IDs (e.g. `customfield_10001`), not display names
3. **Paging**: JIRA API paging is `startAt`/`maxResults`, not skip/take
4. **Session State**: Module stores server config in AppData, may persist between sessions
5. **TLS**: Module explicitly enables TLS 1.2 for older PowerShell versions

