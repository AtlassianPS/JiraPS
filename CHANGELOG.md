# Change Log

## [Unreleased]

This release focuses on **authentication improvements** and **performance optimizations**.

**Authentication**: We've heard the feedback — authenticating with Jira has been painful, especially for CI/CD pipelines and automation scripts. `New-JiraSession` now has first-class support for modern authentication methods:

- **Jira Cloud**: Use `-ApiToken` with `-EmailAddress` — no more manually constructing Basic auth headers
- **Jira Data Center**: Use `-PersonalAccessToken` (aliases: `-PAT`, `-BearerToken`) for Personal Access Tokens — the recommended method since DC 8.14

Both accept `SecureString` and work seamlessly in automation. See the updated [authentication documentation](https://atlassianps.org/docs/JiraPS/about/authentication.html) for examples including environment variables and CI/CD patterns.

> **Note**: OAuth 2.0 (3LO) helpers for Jira Cloud are tracked in [#101](https://github.com/AtlassianPS/JiraPS/issues/101) and will be addressed in a future release.

**Performance**: Frequently-used metadata (fields, issue types, priorities, server info) is now cached automatically. This significantly reduces API calls in scripts that process many issues. Use `-Force` to bypass the cache when needed, or `Clear-JiraCache` to reset it.

**Resilience**: HTTP retry logic now handles 503 errors (common during Jira maintenance), adds jitter to prevent thundering herd, and caps retry delays at 60 seconds.

### Removed (Breaking)

- **BREAKING**: Removed deprecated `-StartIndex` and `-MaxResults` parameters from `Get-JiraIssue`. Use the standard `-Skip` and `-First` paging parameters instead.
- **BREAKING**: Removed deprecated `-StartIndex` and `-MaxResults` parameters from `Get-JiraGroupMember`. Use the standard `-Skip` and `-First` paging parameters instead.
- **BREAKING**: `Set-JiraIssue -Assignee` no longer accepts the magic strings `'Unassigned'` or `'Default'`. Use the new `-Unassign` and `-UseDefaultAssignee` switches instead.
- **BREAKING**: `Set-JiraIssue -Assignee` no longer accepts `$null` or empty/whitespace strings. Use the new `-Unassign` switch instead.
- **BREAKING**: `Invoke-JiraIssueTransition -Assignee` no longer accepts the magic string `'Unassigned'`, `$null`, or empty/whitespace strings. Use the new `-Unassign` switch instead.
- **BREAKING**: `Set-JiraIssue` and `Invoke-JiraIssueTransition` now use parameter sets to make `-Assignee`, `-Unassign`, and `-UseDefaultAssignee` mutually exclusive at parameter binding time.
- **BREAKING (soft)**: `New-JiraIssue -Reporter` no longer accepts `$null`, empty, or whitespace-only strings. Previously these were silently forwarded to Jira (which rejected them with an opaque server error); they are now rejected at parameter binding with an actionable message. Omit `-Reporter` to let Jira apply the project's default reporter.
- **BREAKING**: Renamed the historic `JiraPS.<Type>` PSTypeName for the eight most-used domain types to `AtlassianPS.JiraPS.<Type>`, in line with how every other AtlassianPS module (e.g. ConfluencePS) namespaces its types.
  Affected types: `Issue`, `User`, `Project`, `Filter`, `Version`, `Comment`, `Session`, `ServerInfo`.
  Scripts that test `if ('JiraPS.Issue' -in $obj.PSObject.TypeNames)` must switch to `'AtlassianPS.JiraPS.Issue'` (or use the more idiomatic `$obj -is [AtlassianPS.JiraPS.Issue]`).
  Mocks built as `[PSCustomObject]@{ PSTypeName = 'JiraPS.Issue'; ... }` must use `'AtlassianPS.JiraPS.Issue'`.
  All `[PSTypeName('JiraPS.X')]` parameter attributes and `[ValidateScript]` blocks inside the module were updated accordingly.
  No legacy alias is added — the rename is intentional and final.
  The remaining 16 leaf types (`Group`, `Status`, `Priority`, `IssueType`, `IssueLink`, `IssueLinkType`, `Component`, `Attachment`, `Worklogitem`, `ProjectRole`, `Field`, `CreateMetaField`, `EditMetaField`, `Transition`, `Link`, `FilterPermission`) are tracked for a follow-up phase and still use the legacy `JiraPS.<Type>` PSTypeName until then.

See [`about_JiraPS_MigrationV3`](https://atlassianps.org/docs/JiraPS/about/migration-v3.html) for migration examples.

### Added

- Added `-Unassign` switch to `Set-JiraIssue` and `Invoke-JiraIssueTransition` as the explicit way to remove the assignee from an issue.
- Added `-UseDefaultAssignee` switch to `Set-JiraIssue` as the explicit way to assign an issue to the project's default assignee, replacing the removed `-Assignee 'Default'` magic string.
- Added first-class `-Assignee` and `-Unassign` parameters to `New-JiraIssue` (mutually exclusive parameter sets `AssignToUser` / `Unassign`). `-Assignee` accepts a username, an `accountId`, or a `JiraPS.User` object and uses the same Cloud / Data Center dispatch as `Set-JiraIssue`. There is intentionally no `-UseDefaultAssignee` switch on `New-JiraIssue`: omitting `-Assignee` already lets Jira's create endpoint apply the project default.
- Added `Invoke-Build -Task TestIntegration` for running integration tests with parallel execution support
- Added `-Tag`, `-ExcludeTag`, and `-ThrottleLimit` parameters to `Invoke-Build` for test filtering
- Added `Tests/Invoke-ParallelPester.ps1` script for parallel test execution (requires PowerShell 7+)
- Added comprehensive integration test suite for Jira Cloud (21 test files covering authentication, issues, search, comments, attachments, transitions, issue links, watchers, and more)
- Added `-PersonalAccessToken` parameter to `New-JiraSession` for Personal Access Token (PAT) authentication on Jira Data Center, with `-PAT` and `-BearerToken` aliases (#576)
- Added `-ApiToken` and `-EmailAddress` parameters to `New-JiraSession` for API token authentication on Jira Cloud (#576)
- Added `-CacheKey`, `-CacheExpiry` (as `[TimeSpan]`), and `-BypassCache` parameters to `Invoke-JiraMethod` for built-in response caching (#576)
- Added caching to `Get-JiraField`, `Get-JiraIssueType`, and `Get-JiraPriority` with a `-Force` parameter to bypass the cache (#576)
- Added `Clear-JiraCache` public function to clear cached API responses by type (#576)
- Added "Automation and CI/CD" section to authentication documentation with programmatic SecureString examples (#576)
- Added `ConvertTo-JiraTable` as the descriptive replacement for `Format-Jira`.
  The new name reflects what the cmdlet actually does: it returns a `[String]` of Jira wiki-markup table syntax, not a host-only `Format-*` display object.

### Changed

- Renamed `Format-Jira` to `ConvertTo-JiraTable`.
  The old name is preserved as a deprecated exported alias for backward compatibility and will be removed in a future major version.
  Update scripts to call `ConvertTo-JiraTable` directly.
- Promoted the eight most-used JiraPS domain types (`Issue`, `User`, `Project`, `Filter`, `Version`, `Comment`, `Session`, `ServerInfo`) to real .NET classes under the `AtlassianPS.JiraPS.*` namespace.
- Promoted the eight most-used JiraPS domain types (`Issue`, `User`, `Project`, `Filter`, `Version`, `Comment`, `Session`, `ServerInfo`) to real .NET classes under the `AtlassianPS.JiraPS.*` namespace, mirroring the long-standing convention used by `ConfluencePS` and other AtlassianPS modules.
  The classes are compiled once per session from a single `JiraPS/Types/AtlassianPS.JiraPS.cs` file via `Add-Type` in the module's `#region Dependencies` block; the type-presence guard keeps re-imports cheap.
  Returned objects have `GetType().FullName -eq 'AtlassianPS.JiraPS.<Type>'`, surface real properties to `Get-Member` and IDE IntelliSense, and accept hashtable initialization (`[AtlassianPS.JiraPS.User]@{ Name = 'jdoe' }`).
  Cross-reference slots are strongly typed: `Project.Lead` is `[User]`, `Issue.Project` is `[Project]`, `Comment.Author`/`UpdateAuthor` are `[User]`, `Filter.Owner` is `[User]`. Slots that legitimately hold polymorphic values (e.g. `Issue.Assignee` may be a `User` OR the legacy string `"Unassigned"`) stay typed as `[object]`.
  A new private `ConvertTo-Hashtable` helper handles the Windows PowerShell 5.1 wrinkle where casting a `PSCustomObject` directly to a custom .NET class throws `PSInvalidCastException` — every converter laundering payloads through this helper before the class cast (the same workaround `ConfluencePS` ships).
  `JiraPS.format.ps1xml` selectors now reference `<TypeName>AtlassianPS.JiraPS.Issue</TypeName>` and `<TypeName>AtlassianPS.JiraPS.User</TypeName>` directly; legacy entries were dropped because `PSObject.TypeNames` of a true .NET instance is the .NET full name, so the format-data engine matches automatically.
  See the **Removed (Breaking)** section above for the user-visible PSTypeName rename and migration steps. The remaining 16 leaf types (`Group`, `Status`, `Priority`, `IssueType`, `IssueLink`, `IssueLinkType`, `Component`, `Attachment`, `Worklogitem`, `ProjectRole`, `Field`, `CreateMetaField`, `EditMetaField`, `Transition`, `Link`, `FilterPermission`) are tracked for a follow-up phase.
- Tightened the property slot types on the eight `AtlassianPS.JiraPS.*` classes to match what the Jira Cloud v3 and Data Center v2 REST APIs actually return: `User.Groups` is now `[string[]]`, `Issue.Creator` and `Issue.Reporter` are now `[AtlassianPS.JiraPS.User]`, `Issue.Comment` is now `[AtlassianPS.JiraPS.Comment[]]`, `Issue.Description` and `Comment.Body` are now `[string]`, `ServerInfo.ScmInfo` is now `[string]`, and `ServerInfo.BuildNumber` is now `[long?]`.
  These are lossless tightenings — the converters were already producing values of the new slot types; the change just lets `Get-Member`, IntelliSense, and `[ValidateScript]` see them.
- **BREAKING (soft)**: Tightened the boolean and numeric slot types on `Filter` and `Version`. `Filter.Favourite`, `Version.Archived`, `Version.Released`, and `Version.Overdue` are now `[bool]` (were `[object]`); `Version.Project` is now `[long?]` (was `[object]`).
  When the corresponding wire field is omitted from the payload, the boolean slots now surface as `$false` instead of `$null` (matching the Jira REST documentation, which describes a missing flag as "not set"). Scripts that distinguish "absent" from "false" via `if ($null -eq $f.Favourite)` need to switch to a different signal — the field is always `$true` or `$false` now.
  See [`about_JiraPS_MigrationV3`](https://atlassianps.org/docs/JiraPS/about/migration-v3.html) for migration examples.
- **BREAKING**: `Version.StartDate` and `Version.ReleaseDate` are now `[DateTime?]` (were `[object]`). The empty-string sentinel that the v2 converter emitted when a date was missing is gone — the slots are `$null` instead. Scripts that tested `if ($v.StartDate -eq '')` need to switch to `if ($null -eq $v.StartDate)` (or simply `if (-not $v.StartDate)`, which still works for both shapes).
  See [`about_JiraPS_MigrationV3`](https://atlassianps.org/docs/JiraPS/about/migration-v3.html).

### Added

- Surface fields the eight `AtlassianPS.JiraPS.*` converters previously dropped, so scripts can read them without re-querying the raw payload:
  - `User.AccountType` (Cloud), `User.Deleted` (DC, `[bool?]`), `User.LastLoginTime` (DC, `[DateTime?]`).
  - `Project.ProjectTypeKey`, `Project.Url`, `Project.Email`, plus the optional flags `Project.Archived`, `Project.Simplified`, `Project.IsPrivate` (all `[bool?]`).
  - `Comment.RenderedBody` (DC, populated when the request used `expand=renderedBody`) and `Comment.Properties` (Cloud entity-properties array).
  - `ServerInfo.VersionNumbers` (the parsed `[int[]]` form of `Version`, e.g. `9, 17, 0`) and `ServerInfo.DisplayUrl` (DC's externally-visible base URL).
  - `ServerInfo.DisplayUrlConfluence` and `ServerInfo.DisplayUrlServicedeskHelpCenter` (DC, populated when Jira is paired with Confluence / Service Desk so callers can build cross-product links without extra round-trips).
  - `ServerInfo.BuildPartnerName` (DC OEM attribution), `ServerInfo.ServerTimeZone` (DC `{ id, displayName }`), and `ServerInfo.DefaultLocale` (DC `{ locale }`); the latter two stay typed as `[object]` because their wire shape is a side-band wrapper that no other class consumes.
- `Get-JiraIssue -Key` now accepts pipeline input by property name, enabling `Get-JiraIssue TEST-1 | Get-JiraIssue` to refresh issue data. **Soft breaking change**: Objects with a `Key` property (e.g., `[PSCustomObject]@{ Key = 'TEST-1' }`) now bind to `-Key` instead of failing. Scripts relying on the previous failure behavior may need adjustment.
- `Invoke-Build -Task Test` now excludes integration tests by default (use `-Tag 'Integration'` to include them)
- `Invoke-JiraMethod` now supports Jira-doc style relative endpoint paths (for example, `/rest/api/2/issue/TEST-1`) and resolves them against `Get-JiraConfigServer`.
  Relative paths must start with `/`, otherwise the cmdlet now throws a clear terminating argument error that includes the rejected path.
  Absolute URLs are still supported for backward compatibility (including values coming from object `RestURL` properties).
- Public cmdlets now pass relative `/rest/api/...` endpoints into `Invoke-JiraMethod` instead of concatenating `Get-JiraConfigServer` at each call site.
- Enhanced `Test-ServerResponse` to handle HTTP 503 (Service Unavailable) with retry, jitter on backoff delays, and 60-second max delay cap (#576)
- Enhanced `Resolve-JiraError` to parse all Jira error response formats: `message`, `errorMessage`, `errorMessages` array, and `errors` dictionary (#576)
- Hid internal `-Cmdlet` and `-_RetryCount` parameters on `Invoke-JiraMethod` from tab-completion via `[Parameter(DontShow)]` (follow-up to #582)
- Hardened the `GenerateExternalHelp` build task with explicit command-count and file-existence assertions, warnings on multi-fence examples, and UTF-8-with-BOM encoding for about-topic files (follow-up to #582/#587)
- Migrated all 64 command markdown files in `docs/en-US/commands/` to the PlatyPS 1.0 native schema (`document type: cmdlet`, fenced YAML parameter metadata, `### -Parameter` headings with full `Aliases`, `AcceptedValues`, `PSTypeName`, and `DefaultValue` blocks).
  The `GenerateExternalHelp` task is now a thin `Import-MarkdownCommandHelp | Export-MamlCommandHelp` pipeline plus an inlined MAML post-processing step that re-injects `aliases`/`pipelineInput`/`<dev:defaultValue>` and re-splits each example's `<dev:code>`/`<dev:remarks>` from the `<maml:introduction>` blob (which `Export-MamlCommandHelp` still drops).
  The previous ~250-line `Repair-MamlMetadata` helper, the bracket pre-strip pass, and the example splitter were all removed.
  Markdown is now the single source of truth for help (the build only reads, never patches, the markdown).
  `Get-Help -Full` has no semantic regressions for any of the 64 cmdlets and the rendered Jekyll site has no content regressions (verified with side-by-side `_site/` builds).
  Some `## INPUTS` sections gained additional types that PlatyPS 1.0 introspects from the cmdlet's parameter signatures where master had hand-curated empty or shorter lists.
  The bracket-wrapping convention used in master headings (`### [JiraPS.Issue[]]`) is no longer recommended because Markdig strips the brackets — type names now appear unwrapped (`### JiraPS.Issue`).
  A `Help.Tests.ps1` regression guard rejects single-character names, `Markdig.*` parser internals, and stray `<TODO>` placeholders.

### Internal

- Sped up `Invoke-Build -Task Test` by ~45% (~32 s → ~20 s on macOS, larger on Windows).
  `Initialize-TestEnvironment` (`Tests/Helpers/TestTools.ps1`) now caches the JiraPS module across Pester files via a source-tree fingerprint stored in the module's own scope, so a full run reimports once instead of once per file (~96 → 1).
  All ~117 test files migrated to the new contract.
  Behaviour covered by `Tests/TestTools.Tests.ps1`. (#600)
- Deferred `Get-Help` discovery in `Tests/Help.Tests.ps1` from `BeforeDiscovery` to a per-cmdlet `BeforeAll` and short-circuited the parameter matrix in source mode (where the `Help` / `Parameter` contexts are `-Skip`'d).
  Source-mode runs drop from ~8.9 s to ~4.6 s (-48%). (#600)
- Replaced live `postman-echo.com` round-trips in `Tests/Functions/Public/Invoke-JiraMethod.Unit.Tests.ps1` with an offline `MemoryStream`-backed response factory mirroring postman-echo's `{ args, headers, data, url }` shape.
  The file drops from ~9.5 s to ~2 s and no longer needs network connectivity. (#600)
- Cut ~2 s of fixed overhead from every `Invoke-Build` invocation by removing the `BuildHelpers` build-time dependency and dropping the eager `#requires PowerShellGet` directive from `Tools/BuildTools.psm1`.
  Static path `BH*` env vars are populated directly from `$PSScriptRoot`; the diagnostic `BH*` vars used by `ShowDebugInfo` (branch, commit hash, commit message, build number, build system) are derived inline from `$env:GITHUB_*` or `git` and only computed when that task runs.
  Cold overhead drops from ~2.4 s to ~225 ms (-90%).
  Warm overhead drops from ~200 ms to ~30 ms. (#600)
- Made `GenerateExternalHelp` incremental via Invoke-Build's `-Inputs` / `-Outputs`, with a companion `RemoveOrphanedExternalHelp` task that trims locale dirs / `about_*.help.txt` / `*-help.xml` artifacts whose markdown source has been removed.
  `Clean` no longer wipes `JiraPS/<locale>/` (it's an inter-build cache; `Release/` is still rebuilt from scratch).
  Warm `GenerateExternalHelp` drops from ~550 ms to ~20 ms (-95%).
  Inner-loop `Invoke-Build -Task Build` drops from ~3.4 s to ~1.0 s. (#600)
- Narrowed `Invoke-ScriptAnalyzer`'s scope in the `Lint` task from the full project root to the actual code roots (`JiraPS/`, `Tests/`, `Tools/`, `JiraPS.build.ps1`), avoiding redundant parsing of the ~130 duplicated files under `Release/`.
  Cold `Invoke-Build -Task Lint` drops from ~17.7 s to ~16.0 s.
  Warm runs drop from ~3.2 s to ~1.8 s (-43%). (#600)
- Modernized hot-path code now that PowerShell 5.1 is the floor:
  - Replaced `System.Collections.ArrayList` with `[System.Collections.Generic.List[T]]` in `New-JiraIssue`, `ConvertTo-JiraGroup`, and `Set-JiraIssueLabel` (the latter now initializes via constructor from existing labels).
  - Pre-compiled the regex patterns used by `ConvertTo-AtlassianDocumentFormat` once at module load.
  - Replaced in-loop string concatenation in `ConvertTo-GetParameter` with array-collect + `-join`.
  - Replaced `Get-Member -MemberType *Property` lookups with direct `PSObject.Properties` access in `Format-Jira`, `Add-JiraIssueLink`, `Remove-JiraIssueLink`, `Resolve-JiraError`, `Expand-Result`, `ConvertTo-JiraCreateMetaField`, and `ConvertTo-JiraEditMetaField`.
- Extracted user-reference payload construction into a private `Resolve-JiraUserPayload` helper shared by `Set-JiraIssue`, `Invoke-JiraIssueTransition`, and `New-JiraIssue` (and reusable for any future cmdlet that needs to point at a Jira user — assignee, reporter, etc.). As a side-effect, `Invoke-JiraIssueTransition -Unassign` on Jira Cloud now correctly emits `{accountId: null}` instead of `{name: ""}`. The helper also throws explicitly when handed a Cloud user object that has no `AccountId`, instead of silently emitting an unassign payload.
- `New-JiraIssue -Reporter` now resolves the user via `Resolve-JiraUser` on Jira Server / Data Center too (previously only resolved on Jira Cloud). Typo'd usernames are now caught client-side instead of producing an opaque server error from the create endpoint.

### Fixed

- Fixed `Get-JiraIssue` prompting for input when piping JiraPS.Issue objects (added `ValueFromPipelineByPropertyName` to `-Key` parameter)
- Fixed long-standing typo in `Invoke-JiraIssueTransition` where the transition-cast error path constructed its `ErrorRecord` against an undefined `$errorTargetError` variable instead of `$errorTarget`.
- Fixed `ConvertTo-GetParameter` returning `'?'` for an empty hashtable; it now returns `''` again, matching its prior contract and preventing accidental trailing `?` in URLs.
- Fixed PlatyPS 1.0 MAML regressions introduced in #582: every `<command:parameter>` was emitted with `aliases="none"` and `pipelineInput="false"`, `<dev:defaultValue>` was never written, `### [Type]` INPUTS/OUTPUTS headings collapsed to a literal `[` typename, and fenced example code was buried inside `maml:introduction` instead of `dev:code`/`dev:remarks`. `Get-Help` now correctly reports aliases, pipeline binding, default values, typed INPUTS/OUTPUTS, and split code/remarks for every example. Parameter aliases and pipeline flags are read back from the live module via reflection, so the source code is the single source of truth (no markdown drift).
- Fixed `ConvertTo-JiraServerInfo` throwing when `BuildDate` or `ServerTime` are null in API response (now returns `$null` for these fields). **Soft breaking change**: Scripts accessing `.BuildDate.Year` or similar will throw `NullReferenceException` on Cloud instances that omit these fields.
- Fixed `Invoke-PaginatedRequest` crashing with "Cannot bind argument to parameter 'InputObject'" when API returns null during pagination (now writes warning and returns partial results)
- Fixed module load race condition when multiple processes import JiraPS simultaneously (gracefully handles concurrent config file creation)
- Fixed config file parsing to handle both CRLF and LF line endings correctly
- `Get-JiraIssueCreateMetadata` now walks all pages of the Jira Cloud createmeta response instead of truncating at the default page size. The cmdlet opts into `SupportsPaging`, so `-First`, `-Skip`, and `-IncludeTotalCount` are also supported.
- Fixed stale documentation for `New-JiraIssue -Reporter`: the reference page reported `Accept pipeline input: False`, but the parameter has accepted `ValueFromPipelineByPropertyName` since v2. The Markdown source and regenerated `JiraPS-help.xml` now reflect the actual binding.
- Fixed `Get-JiraIssueEditMetadata` emitting `"No metadata found for project  and issueType ."` (with empty interpolated values) when an issue lookup failed.
  The null-result `ErrorRecord` interpolated `$Project` and `$IssueType`, neither of which is a parameter of this cmdlet, so the message was always garbled.
  It now references the actual `-Issue` parameter and uses `$PSCmdlet.ThrowTerminatingError` to match other JiraPS cmdlets.
  The same `if ($result)` block also carried four `Write-Error` branches that validated the createmeta envelope shape (`$result.fields.projects` / `.issuetypes`) — fields the editmeta endpoint never returns, so those branches were unreachable dead code copy-pasted from `Get-JiraIssueCreateMetadata` and have been removed.
- Cleaned up `## INPUTS` sections across 35 cmdlets (follow-up to the PlatyPS 1.0 migration in #596).
  `New-MarkdownCommandHelp` introspected every parameter signature and added `### System.Object[]`, `### System.String[]`, `### System.SwitchParameter`, `### System.TimeSpan`, `### System.DateTime` and similar headings that had never been part of the hand-curated docs and were either redundant with the matching `### JiraPS.<Type>` entry or actively misleading (switches and value types are not pipeline objects).
  All 35 spurious `### System.*` headings were removed.
  Four cmdlets (`Add-JiraIssueAttachment`, `Add-JiraIssueComment`, `Add-JiraIssueWatcher`, `Add-JiraIssueWorklog`) had a long-standing master-era documentation bug where the entire prose sentence "This function can accept JiraPS.Issue objects via pipeline." served as the type heading; these were replaced with a real type heading plus the explanation as a paragraph.
  In particular `Add-JiraIssueAttachment` claimed to accept `JiraPS.Issue` from the pipeline, but the only pipeline-bound parameter on that cmdlet is `-FilePath [String[]]`; the docs now say so.
  `Get-JiraUser` had `### String` from a Markdig bracket-strip (master was `[String[]]`) — now correctly `### String[]`.
  Pre-existing legitimate `### JiraPS.*` headings discovered by PlatyPS via `[PSTypeName(...)]` attributes were kept (they reflect what the parameters actually accept).
  `Remove-JiraFilterPermission` had `### System.Object` from master that didn't reflect the actual `[PSTypeName('JiraPS.Filter')]` parameter; replaced with `### JiraPS.Filter`.
  A new Pester guard (`does not list Object[] / System.Object[] as a pipeline INPUT type`) prevents the most common PlatyPS-introspection noise from creeping back in.
  Bare `### System.Object` is still allowed for cmdlets like `ConvertFrom-AtlassianDocumentFormat` whose `[Object]` parameter genuinely accepts any object.

## 3.0 - 2026-04-17

### Changed

- **BREAKING**: Minimum PowerShell version raised from 3.0 to 5.1. Windows PowerShell 3.x and 4.x are no longer supported.
- Removed custom `ConvertFrom-Json` override (PS 5.1 native cmdlet has sufficient 2GB JSON limit)
- Removed legacy PSv3 workaround for Accept header in module initialization

## 2.16 - 2026-04-13

### Added

- Added Jira Cloud compatibility — the module now auto-detects Cloud vs Data Center/Server via `Get-JiraServerInformation` and adapts API calls accordingly
- Added `ConvertFrom-AtlassianDocumentFormat` public function (alias `ConvertFrom-ADF`) — converts ADF objects (Jira Cloud v3) to Markdown; plain strings (Data Center) are passed through unchanged
- Added `ConvertTo-AtlassianDocumentFormat` public function (alias `ConvertTo-ADF`) — converts Markdown to ADF for writing descriptions and comments on Jira Cloud v3
- Added `-AccountId` parameter to `Get-JiraUser` for Cloud's account-based user lookup
- Added `-Force` parameter to `Get-JiraServerInformation` to bypass the server info cache
- Added HTTP 429 rate limit handling with automatic retry (respects `Retry-After` header, exponential backoff)
- Added Jira Cloud vs Data Center compatibility guidance in documentation

### Changed

- User operations now use `accountId` on Cloud, `username`/`name` on Data Center (`Get-JiraUser`, `Set-JiraUser`, `Remove-JiraUser`, `New-JiraIssue`, `Set-JiraIssue`, `Invoke-JiraIssueTransition`, `Add-JiraGroupMember`, `Remove-JiraGroupMember`, `Add-JiraIssueWatcher`, `Remove-JiraIssueWatcher`, `Resolve-JiraUser`)
- `Get-JiraIssue` JQL search uses `/rest/api/3/search/jql` with token-based pagination on Cloud
- `Get-JiraServerInformation` now caches its result in module scope; subsequent calls return cached data (cleared on `Set-JiraConfigServer` or with `-Force`)
- `ConvertTo-JiraComment` and `ConvertTo-JiraIssue` now convert ADF responses to readable Markdown text
- `ConvertTo-JiraUser.ToString()` falls back to `DisplayName` or `AccountId` when `Name` is empty (GDPR compliance)
- `Get-JiraIssueWatcher` now pipes watchers through `ConvertTo-JiraUser` for consistent typed output
- Modernized test infrastructure and standardized helper utilities (#549)
- Bumped GitHub Actions: `actions/upload-artifact` v7, `actions/download-artifact` v8, `dawidd6/action-download-artifact` v19

### Fixed

- Enforced UTF-8 with BOM across all PowerShell files for PS v5 compatibility (#574)
- Fixed `inlineCard` rendering in `ConvertFrom-ADF` to produce `<url>` instead of redundant `[url](url)`
- Fixed table separator regex in `ConvertTo-ADF` to handle compact separators without spaces
- Fixed typos and casing errors in test assertions and fixtures (#566)

## 2.15 - 2025-12-30

### Added

- Added `-Components` to `New-JiraIssue`. This will be a comma-separated list of Component IDs. (#483, [@micheleliberman])
- Added `Get-JiraIssueWorklog` (#451, [@asherber])
- Allow `New-JiraSession` to be called without `-Credential` so to use `-Header` (#439, [@pwshmatt])

### Changed

- Improved `-Transition` behavior in `Invoke-JiraIssueTransition` (#416, [@Rufus125])
- Updated Pester to v5 (#543, [@SrBlackVoid])

### Fixed

- Fixed example and improved documentation on `-Properties` hashtable for `Set-JiraUser` (#509, [@jschlackman])
- Fixed `Get-JiraIssueCreateMetadata` to conform with Atlassian's API changes ([documentation](https://confluence.atlassian.com/jiracore/createmeta-rest-endpoint-to-be-removed-975040986.html)) (#488, [@robertmbaker])
- Removed `reporter` from `New-JiraIssue` when project is "next-gen" (#407, [@LaurentGoderre])
- Fixed `-ErrorAction` in `Add-JiraGroupMember` (#426, [@spascoe])
- Fixed copy/paste error in test files for `Get-JiraIssue` (#427, [@borislol])
- Fixed JSON conversion in `Invoke-JiraIssueTransition` (#417, [@Rufus125])
- Fixed type in `Invoke-JiraIssueTransition` (#417, [@Rufus125])

## 2.14 - 2020-03-28

### Changed

- Changed all commands to only use Jira's api version 2. (#409, [@lipkau])
  This is a temporary fix and should be reverted to version `latest` as soon as
  a proper handling of how users work between cloud and on-premise is
  implemented

## 2.13 - 2020-02-23

### Added

- Add support for activation/deactivation of accounts via `Set-JiraUser` (#385, [@johnheusinger])

### Changed

- Removed progress bar from `Invoke-WebRequest` for better performance (#380, [@sgtwilko])

## 2.12 - 2019-08-15

### Added

- Added cmdlet for sorting versions: `Move-JiraVersion` (#363, [@kb-cs])
- Added cmdlet for finding filters by name: `Find-JiraFilter` (#365, [@vercellone])

### Changed

- Changed the way users as interpreted by functions (#369, [@lipkau])
- Changed how the config of a jira server is stored (#370, [@lipkau])

## 2.11 - 2019-07-02

### Added

- Unit test for synopsis in cmdlet documentation (#344, [@alexsuslin])

### Changed

- `Invoke-JiraIssueTransition` to find username with exact match (#351, [@mirrorgleam])
- Fixed `-Add <String>` parameter for `Set-JiraIssueLabel` on issues without labels (#358, [@lipkau])

## 2.10 - 2019-02-21

### Added

- Parameter for retrieving information about a specific user with `Get-JiraUser` (#328, [@michalporeba])
  - this implementations will be changed with the next major update in favor of #306

### Changed

- Fixed logic of how to retrieve components from project (#330, [@lipkau])
- Fix usage of `New-JiraIssue` in Jira Environment with mixed classic and "next gen" projects (#337, [@nojp])
- Fixed `Get-JiraIssueAttachmentFile` to use `Accept` header based on Mime time of attachment (#333, [@wisemoth])
- Fixed incorrect handling of skip notifications when updating an issue (#339, [@lipkau])

## 2.9 - 2018-12-12

### Added

- Parameter for selecting what fields to return the the issue's payload (#300, [@tuxgoose])
- Added pipeline support to `New-JiraIssue` (#312, [@ctolan])
- Added parameter to avoid notifying user when running `Set-JiraIssue` (#315, [@alexsuslin])
- Improved documentation to demonstrate how to authenticate with 2FA (#313, [@lipkau])
- Added function to download attachments from issue: `Get-JiraIssueAttachmentFile` (#323, [@lipkau])

### Changed

- Fixed the way a user is resolved in `Remove-JiraGroupMember` (#301, [@lipkau])
- Improved the resolving of server responses with an error (#303, [@lipkau])
- Fixed payload of `New-JiraFilter` (#304, [@lipkau])
- Fixed paging when server responds with only 1 result (#307, [@lipkau])
- Fixed `Set-JiraIssue` to allow to unassigned an issue (#309, [@lipkau])
- Changed CI/CD pipeline from AppVeyor to Azure DevOps (#317, [@lipkau])
- Fixed missing properties on `Get-JiraUser` (#321, [@lipkau])
- Fixed `-DateStarted` on `Add-JiraIssueWorklog` (#324, [@lipkau])

## 2.8 - 2018-06-28

More detailed description about the changes can be found on [Our Website](https://atlassianps.org/article/announcement/JiraPS-v2.8.html).

### Changed

- Added support for paginated response from API server by means of `-Paging` (#291, [@lipkau[]])
- Added full set of functions to manage Filter Permissions (#289, [@lipkau[]])
- Added `-Id` parameter to `Remove-JiraFilter` (#288, [@lipkau[]])
- Changed logic of `Get-JiraUser` to return multiple results for a search (#272, [@lipkau[]])
- Added posts for homepage to the module's repository (#268, [@lipkau[]])
- Improved handling of _Credentials_ (#271, [@lipkau[]])
- Added missing interactions with _Filters_ (#266, [@lipkau[]])
- Added `Remove-JiraIssue` (#265, [@hmmwhatsthisdo[]])
- Improved Build script (to deploy changes to the homepage) (#259, [@lipkau[]])

### Fixed

- Reverted `Add-JiraIssueAttachment` as JiraPS v2.7 broke it (#287, [@lipkau[]])
- Fixed resolving of Remote Link (#286, [@lipkau[]])
- Improved error handling for ErrorDetails and non-JSON/HTML responses (#277, [@hmmwhatsthisdo[]])
- Fully support Powershell v3 (#273, [@lipkau[]])
- Fixed parameter used in documentation but not in code (#263, [@lipkau[]])

## 2.7 - 2018-05-13

More detailed description about the changes can be found on [Our Website](https://atlassianps.org/article/announcement/JiraPS-v2.7.html).

### Changed

- Writing and throwing of errors show better context (#199, [@lipkau][])
- Improved validation of parameters in `Add-JiraGroupMember` (#250, [@WindowsAdmin92][])
- Improved casting to `-Fields` by defining it's type as `[PSCustomObject]` (#255, [@lipkau][])
- Several improvements to the CI pipeline (#252, #257, [@lipkau][])

### Fixed

- Build script was not publishing to the PSGallery (#252, [@lipkau][])
- Build script was publishing a new tag to repository even in case the build failed (#252, [@lipkau][])
- Fixed the adding multiple labels and the removal of those in `Set-JiraIssueLabel` (#244, [@lipkau][])
- Fixed CI icon in README (#245, [@lipkau][])
- Allow `Get-JiraUser` to return more than 1 result (#246, [@lipkau][])

## 2.6 - 2018-05-02

More detailed description about the changes can be found on [Our Website](https://atlassianps.org/article/announcement/JiraPS-v2.6.html).

### Added

- `-Passthru` parameter to `Invoke-JiraIssueTransition` (#239, [@lipkau][])
- `Get-JiraUser` functionality to find the current user (#231, [@lipkau][])
- full support for PowerShell Core (v6) and Linux/MacOS support (#230, [@lipkau][])
- JiraPS documentation on the homepage (#230, [@lipkau][])

### Changed

- Exposed `Invoke-JiraMethod` as a public function (#233, [@lipkau][])
- Migrated to External Help (instead of Comment-Based Help) (#230, [@lipkau][])

### Fixed

- Index Into Null Object (#209, [@lipkau][])
- Fix empty header (#206, [@lipkau][])
- Bad Body (#224, [@lipkau][])
- Add Labels to array (#226, [@lipkau][])
- Fix removing labels with `Set-JiraIssueLabel -Remove` (#244, [@lipkau][])
- Fix adding of multiple labels at once with `Set-JiraIssueLabel -Add` (#244, [@lipkau][])

## 2.5 - 2018-03-23

More detailed description about the changes can be found on [Our Website](https://atlassianps.org/article/announcement/JiraPS-v2.5.html).

### Changed

- Harmonized code style (#162, [@lipkau][])
- Harmonized verbose messages (#162, [@lipkau][])
- Harmonized debug messages (#162, [@lipkau][])
- Improved debug behavior (#162, [@lipkau][])
- Update of VS code config to reflect code styling (#162, [@lipkau][])
- Few improvements in test cases (#162, [@lipkau][])
- Added parameter validation (#162, [@lipkau][])
- Updated manifest (#162, [@lipkau][])
- Minor preparations for pwsh support (#162, [@lipkau][])
- Execute Tests against `./Release` (#162, [@lipkau][])
- Removed unused `$ConfigFile` variable (#219, [@lipkau][])
- `Invoke-JiraMethod` now sets the TLS to 1.2 before every call (#84, [@lipkau][])
- Fixed _date_ and _timespan_ representation in _Body_ of `Add-JiraIssueWorklog` (#214, [@lipkau][])
- Improved output of `Get-JiraProject` (#216, [@lipkau][])

## 2.4 (Nov 01, 2017)

### Added

- `Add-JiraIssueAttachment`: Add an attachment to an issue (#137, [@beaudryj][])
- `Get-JiraIssueAttachment`: Get attachments from issues (#137, [@beaudryj][])
- `Remove-JiraIssueAttachment`: Remove attachments from issues (#137, [@beaudryj][])

### Changed

- `JiraPS.Issue` now has a property for Attachments `JiraPS.Attachment` (#137, [@beaudryj][])

## 2.3 (Okt 07, 2017)

### Added

- `Get-JiraServerInformation`: Fetches the information about the server (#187, [@lipkau][])

### Changed

- Added `-AddComment` to `Set-JiraIssue`. Allowing the user to write a comment for the changes to the issue (#167, [@Clijsters][])
- Changed the default visibility of comments (#172, [@lipkau][])
- Added more properties to `JiraPS.User` objects (#152, [@lipkau][])

## 2.2.0 (Aug 05, 2017)

### Added

- `New-JiraVersion`: Create a new Version in a project (#158, [@Dejulia489][])
- `Get-JiraVersion`: Get Versions of a project (#158, [@Dejulia489][])
- `Set-JiraVersion`: Changes a Version of a project (#158, [@Dejulia489][])
- `Remove-JiraVersion`: Removes a Version of a project (#158, [@Dejulia489][])
- New custom object for Versions (#158, [@Dejulia489][])

## 2.1.0 (Jul 25, 2017)

### Added

- `Get-JiraIssueEditMetadata`: Returns metadata required to create an issue in JIRA (#65, [@lipkau][])
- `Get-JiraRemoteLink`: Returns a remote link from a JIRA issue (#80, [@lipkau][])
- `Remove-JiraRemoteLink`: Removes a remote link from a JIRA issue (#80, [@lipkau][])
- `Get-JiraComponent`: Returns a Component from JIRA (#68, [@axxelG][])
- `Add-JiraIssueWorklog`: Add worklog items to an issue (#83, [@jkknorr][])
- Added support for getting and managing Issue Watchers (`Add-JiraIssueWatcher`, `Get-JiraIssueWatcher`, `Remove-JiraIssueWatcher`) (#73, [@ebekker][])
- Added IssueLink functionality (`Add-JiraIssueLink`, `Get-JiraIssueLink`, `Get-JiraIssueLinkType`, `Remove-JiraIssueLink`) (#131, [@lipkau][])

### Changed

- `New-JiraIssue`: _Description_ and _Priority_ are no longer mandatory (#53, [@brianbunke][])
- Added property `Components` to `PSjira.Project` (#68, [@axxelG][])
- `Invoke-JiraIssueTransition`: add support for parameters _Fields_, _Comment_ and _Assignee_ (#38, [@padgers][])
- `New-JiraIssue`: support parameter _FixVersion_ (#103, [@Dejulia489][])
- `Set-JiraIssue`: support parameter _FixVersion_ (#103, [@Dejulia489][])
- Respect the global `$PSDefaultParameterValues` inside the module (#110, [@lipkau][])
- `New-JiraSession`: Display warning when login needs CAPTCHA (#111, [@lipkau][])
- Switched to _Basic Authentication_ when generating the session (#116, [@lipkau][])
- Added more tests for the CI (#142, [@lipkau][])

### Fixed

- `Invoke-JiraMethod`: Error when Invoke-WebRequest returns '204 No content' (#42, [@colhal][])
- `Invoke-JiraIssueTransition`: Error when Invoke-WebRequest returns '204 No content' (#43, [@colhal][])
- `Set-JiraIssueLabel`: Forced label property to be an array (#88, [@kittholland][])
- `Invoke-JiraMethod`: Send ContentType as Parameter instead of in the Header (#121, [@lukhase][])

## 2.0 (Jun 24, 2017)

### Changes to the code module

- Move module to organization `AtlassianPS`
- Rename of the module to `JiraPS` **breaking change**
- Rename of module's custom objects to `JiraPS.*` **breaking change**

## 1.2.5 (Aug 08, 2016)

### Changed

- New-JiraIssue: Priority and Description are no longer mandatory (#24, @lipkau)
- New-JiraIssue: Added -Parent parameter for sub-tasks (#29, @ebekker)

### Fixed

- ConvertTo-JiraProject: updated for Atlassian's minor wording change of projectCategory (#31, @alexsuslin)
- Invoke-JiraMethod: now uses the -ContentType parameter instead of manually passing the Content-Type header (#19)
- New-JiraIssue: able to create issues without labels again (#21)
- Set-JiraIssue: fixed issue with JSON depth for custom parameters (#17, @ThePSAdmin)
- Various: Fixed issues with ConvertFrom-Json max length with a custom ConvertFrom-Json function (#23, @LiamLeane)

## 1.2.4 (Dec 10, 2015)

### Changed

- Get-JiraGroupMember: now returns all members by default, with support for -MaxResults and -StartIndex parameters (#14)
- Get-JiraIssue: significantly increased performance (#12)

### Fixed

- Get-JiraIssue: fixed issue where Get-JiraIssue would only return one result when using -Filter parameter in some cases (#15)
- Invoke-JiraIssueTransition: fixed -Credential parameter (#13)

## 1.2.3 (Dec 02, 2015)

### Added

- Get-JiraIssue: added paging support with the -StartIndex and -PageSize parameters. This allows programmatically looping through all issues that match a given search. (#9)

### Changed

- Get-JiraIssue: default behavior has been changed to return all issues via paging when using -Query or -Filter parameters

### Fixed

- Invoke-JiraMethod: Fixed issue where non-standard characters were not being parsed correctly from JSON (#7)

## 1.2.2 (Nov 16, 2015)

### Added

- Set-JiraIssueLabel: add and remove specific issue labels, or overwrite or clear all labels on an issue (#5)

### Changed

- New-JiraIssue: now has a -Label parameter
- Set-JiraIssue: now has a -Label parameter (this replaces all labels on an issue; use Set-JiraIssueLabel for more fine-grained control)
- Invoke-JiraMethod: handles special UTF-8 characters correctly (#4)

### Fixed

- Get-JiraIssueCreateMetadata: now correctly returns the ID of fields as well (#6)

## 1.2.0 (Oct 26, 2015)

### Changed

- Get-JiraIssueCreateMetadata: changed output type from a generic PSCustomObject to new type PSJira.CreateMetaField
- Get-JiraIssueCreateMetadata: now returns additional properties for field metadata, such as AllowedValues

## 1.2.0 (Oct 16, 2015)

### Added

- Get-JiraFilter: get a reference to a JIRA filter, including its JQL and owner

### Changed

- Get-JiraIssue: now supports a -Filter parameter to obtain all issues matching a given filter object or ID

## 1.1.1 (Oct 08, 2015)

### Changed

- Set-JiraIssue now supports modifying arbitrary fields through the Fields parameter

## 1.1.0 (Sep 17, 2015)

### Added

- User management: create and delete users and groups, and modify group memberships

### Changed

- Cleaner error handling in all REST requests; Jira's error messages should now be passed as PowerShell errors

### Fixed

- PSJira.User: ToString() now works as expected

## 1.0.0 (Aug 5, 2015)

- Initial release

This changelog is inspired by the [Pester](https://github.com/pester/Pester/blob/master/CHANGELOG.md) file,
which is in turn inspired by the [Vagrant](https://github.com/mitchellh/vagrant/blob/master/CHANGELOG.md) file.

## Template

## Next Release

### Added

### Changed

### Fixed

<!-- reference-style links -->

[@alexsuslin]: https://github.com/alexsuslin
[@asherber]: https://github.com/asherber
[@axxelg]: https://github.com/axxelG
[@beaudryj]: https://github.com/beaudryj
[@borislol]: https://github.com/borislol
[@brianbunke]: https://github.com/brianbunke
[@clijsters]: https://github.com/Clijsters
[@colhal]: https://github.com/colhal
[@copilot]: https://github.com/copilot
[@ctolan]: https://github.com/ctolan
[@dejulia489]: https://github.com/Dejulia489
[@ebekker]: https://github.com/ebekker
[@hmmwhatsthisdo]: https://github.com/hmmwhatsthisdo
[@jkknorr]: https://github.com/jkknorr
[@johnheusinger]: https://github.com/johnheusinger
[@jschlackman]: https://github.com/jschlackman
[@kb-cs]: https://github.com/kb-cs
[@kittholland]: https://github.com/kittholland
[@LaurentGoderre]: https://github.com/LaurentGoderre
[@liamleane]: https://github.com/LiamLeane
[@lipkau]: https://github.com/lipkau
[@lukhase]: https://github.com/lukhase
[@michalporeba]: https://github.com/michalporeba
[@micheleliberman]: https://github.com/micheleliberman
[@mirrorgleam]: https://github.com/mirrorgleam
[@nojp]: https://github.com/nojp
[@padgers]: https://github.com/padgers
[@pwshmatt]: https://github.com/pwshmatt
[@robertmbaker]: https://github.com/robertmbaker
[@Rufus125]: https://github.com/Rufus125
[@sgtwilko]: https://github.com/sgtwilko
[@spascoe]: https://github.com/spascoe
[@SrBlackVoid]: https://github.com/SrBlackVoid
[@thepsadmin]: https://github.com/ThePSAdmin
[@tuxgoose]: https://github.com/tuxgoose
[@vercellone]: https://github.com/vercellone
[@windowsadmin92]: https://github.com/WindowsAdmin92
[@wisemoth]: https://github.com/wisemoth
