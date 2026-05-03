# Change Log

## [Unreleased]

This release focuses on **authentication improvements** and **performance optimizations**.

### Changed

- `New-JiraIssue`, `Set-JiraIssue`, and `Invoke-JiraIssueTransition` now resolve `-Fields` entries
  against scoped field metadata (create metadata, edit metadata, or transition screen metadata
  respectively) before falling back to the global `Get-JiraField` catalogue.
  This eliminates the ambiguity when duplicate custom-field display names exist in the same Jira
  instance, because the scoped metadata is constrained to the fields actually on the relevant
  screen, making name-based lookup unambiguous in the common case.
  The fallback to `Get-JiraField` is preserved for fields not surfaced in the scoped metadata.
- `Get-JiraIssueCreateMetadata` now uses the Jira REST API v3 endpoint on Jira Cloud (Cloud
  previously used the v2 path, which is deprecated).
  Data Center continues to use the v2 endpoint unchanged.

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
  The remaining 15 leaf types (`Status`, `Priority`, `IssueType`, `IssueLink`, `IssueLinkType`, `Component`, `Attachment`, `Worklogitem`, `ProjectRole`, `Field`, `CreateMetaField`, `EditMetaField`, `Transition`, `Link`, `FilterPermission`) are tracked for a follow-up phase and still use the legacy `JiraPS.<Type>` PSTypeName until then. (`Group` was promoted in this release — see below.)

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
- Added `-TimeoutSec` parameter to `Invoke-JiraMethod` to bound each HTTP request (default `100` seconds, `0` disables).
  Previously the cmdlet inherited `Invoke-WebRequest`'s per-host default — `Infinite` on PowerShell 7+ — so a hung Jira instance would block the calling pipeline indefinitely.
- Added caching to `Get-JiraField`, `Get-JiraIssueType`, and `Get-JiraPriority` with a `-Force` parameter to bypass the cache (#576)
- Added `Clear-JiraCache` public function to clear cached API responses by type (#576)
- Added `Set-JiraResponseHeaderLogConfiguration` to opt into debug logging for selected Jira response headers, including Data Center diagnostic headers such as `X-AREQUESTID`, `X-ANODEID`, `X-ASESSIONID`, and `X-AUSERNAME` (#536)
- Added `Get-JiraResponseHeaderLogConfiguration` to inspect the active response-header logging configuration (#536)
- Added "Automation and CI/CD" section to authentication documentation with programmatic SecureString examples (#576)
- Added `ConvertTo-JiraTable` as the descriptive replacement for `Format-Jira`.
  The new name reflects what the cmdlet actually does: it returns a `[String]` of Jira wiki-markup table syntax, not a host-only `Format-*` display object.
- Added Jira Data Center integration test infrastructure: deployment-aware `Tests/Helpers/IntegrationTestTools.ps1`, `Server`/`Cloud` Pester tags on every `Describe` block, `docker-compose.yml`, `Tools/Wait-JiraServer.ps1`, `StartJiraDocker`/`StopJiraDocker` build tasks, and a parallel `server_integration_tests` job in `.github/workflows/integration_tests.yml` alongside the existing Cloud track.
  The Server track boots the `moveworkforward/atlas-run-standalone:jira-11` Docker image (Atlassian Plugin SDK 9.6.0 + Jira Software 11.0.1), chosen because its SDK talks to the live `packages.atlassian.com` Artifactory rather than the retired `marketplace.atlassian.com` endpoint that bricks older standalone images.
  Both Cloud and Server jobs run nightly and on `workflow_dispatch` (with an optional `track` input to dispatch one or both); per-PR Cloud coverage is the `smoke_tests` job in `ci.yml`. See [`Tests/Integration/README.md`](Tests/Integration/README.md) for the local quickstart and full track guide.

### Changed

- Refactored `Add-JiraIssueAttachment` to upload files through `Invoke-JiraMethod -InFile`, removing the cmdlet's hand-built multipart body assembly and preserving attachment filename handling for non-ASCII names. (#607)
- `Get-JiraGroup` is now a canonical resolver: Jira Cloud uses `/group/bulk`, while Jira Data Center uses `/group/member` because Jira 11 removed the legacy `GET /group?groupname=` path. The cmdlet no longer synthesizes a group from `/groups/picker` search results. A new private `Resolve-JiraGroupPayload` helper adapts the Jira Data Center group-member payload into the canonical group shape before `ConvertTo-JiraGroup` materializes the returned object. Lookup misses now surface as non-terminating `GroupNotFound` errors, matching PowerShell lookup cmdlet behavior while still honoring `-ErrorAction Stop`. `AtlassianPS.JiraPS.Group` now exposes `Id` as the canonical identifier property and preserves `GroupId` as a compatibility alias. (#606)
- `Get-JiraGroupMember`, `Add-JiraGroupMember`, `Remove-JiraGroupMember`, and `Remove-JiraGroup` no longer require `Get-JiraGroup` as a prerequisite when the REST API can already operate on the supplied group name. On Jira Cloud they use `Id` when the input group already includes one; otherwise they call the documented name-based endpoint directly. Jira Data Center continues to use documented `groupname` paths, so direct name-based calls can still work even when `Get-JiraGroup` cannot resolve the same group. (#606)
- `Add-JiraIssueComment -Comment` is now interpreted as Markdown on Jira Cloud and converted to Atlassian Document Format before being sent, so headings, bold/italic, lists, fenced code blocks, links, and Markdown tables render as rich text in the issue. To accept the ADF payload, the cmdlet now targets the Jira Cloud platform REST API v3 issue endpoint (`/rest/api/3/issue/{id}/comment`) instead of v2 on Cloud. Behaviour on Jira Server / Data Center is unchanged: the text is sent verbatim against the v2 endpoint and continues to honour the legacy wiki-markup syntax. (#602)
- `Add-JiraIssueWorklog -Comment` is now wrapped into Atlassian Document Format on Jira Cloud and posted to the v3 worklog endpoint (`/rest/api/3/issue/{id}/worklog`), matching the comment behaviour above. The corresponding read path (`ConvertTo-JiraWorklogitem`, used by `Get-JiraIssueWorklog`) now renders ADF comment payloads back to plain text on the returned `JiraPS.Worklogitem` object so callers see a readable string regardless of deployment. Server / Data Center behaviour is unchanged. (#602)
- `New-JiraIssue -Description` and `Set-JiraIssue -Description` / `-AddComment` are now interpreted as Markdown on Jira Cloud and converted to Atlassian Document Format before being sent. The create and edit calls are routed to the v3 issue endpoint on Cloud (`/rest/api/3/issue` and `/rest/api/3/issue/{id}`), which is the only Cloud endpoint that accepts ADF for rich-text fields. Behaviour on Jira Server / Data Center is unchanged: the values are sent verbatim against the v2 endpoint. The semantics of `Set-JiraIssue -Description ''` (currently a no-op) are unchanged in this release and tracked separately in the backlog. (#602)
- `Invoke-JiraIssueTransition -Comment` is now wrapped into Atlassian Document Format on Jira Cloud and posted to the v3 transitions endpoint (`/rest/api/3/issue/{id}/transitions`), matching the comment behaviour of `Add-JiraIssueComment`. Server / Data Center behaviour is unchanged. (#602)
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
  See the **Removed (Breaking)** section above for the user-visible PSTypeName rename and migration steps. The remaining 15 leaf types (`Status`, `Priority`, `IssueType`, `IssueLink`, `IssueLinkType`, `Component`, `Attachment`, `Worklogitem`, `ProjectRole`, `Field`, `CreateMetaField`, `EditMetaField`, `Transition`, `Link`, `FilterPermission`) are tracked for a follow-up phase. (`Group` was promoted in this release — see below.)
- Tightened the property slot types on the eight `AtlassianPS.JiraPS.*` classes to match what the Jira Cloud v3 and Data Center v2 REST APIs actually return: `User.Groups` is now `[string[]]`, `Issue.Creator` and `Issue.Reporter` are now `[AtlassianPS.JiraPS.User]`, `Issue.Comment` is now `[AtlassianPS.JiraPS.Comment[]]`, `Issue.Description` and `Comment.Body` are now `[string]`, `ServerInfo.ScmInfo` is now `[string]`, and `ServerInfo.BuildNumber` is now `[long?]`.
  These are lossless tightenings — the converters were already producing values of the new slot types; the change just lets `Get-Member`, IntelliSense, and `[ValidateScript]` see them.
- **BREAKING (soft)**: Tightened the boolean and numeric slot types on `Filter` and `Version`. `Filter.Favourite`, `Version.Archived`, `Version.Released`, and `Version.Overdue` are now `[bool]` (were `[object]`); `Version.Project` is now `[long?]` (was `[object]`).
  When the corresponding wire field is omitted from the payload, the boolean slots now surface as `$false` instead of `$null` (matching the Jira REST documentation, which describes a missing flag as "not set"). Scripts that distinguish "absent" from "false" via `if ($null -eq $f.Favourite)` need to switch to a different signal — the field is always `$true` or `$false` now.
  See [`about_JiraPS_MigrationV3`](https://atlassianps.org/docs/JiraPS/about/migration-v3.html) for migration examples.
- **BREAKING**: `Version.StartDate` and `Version.ReleaseDate` are now `[DateTime?]` (were `[object]`). The empty-string sentinel that the v2 converter emitted when a date was missing is gone — the slots are `$null` instead. Scripts that tested `if ($v.StartDate -eq '')` need to switch to `if ($null -eq $v.StartDate)` (or simply `if (-not $v.StartDate)`, which still works for both shapes).
  See [`about_JiraPS_MigrationV3`](https://atlassianps.org/docs/JiraPS/about/migration-v3.html).
- **BREAKING (soft)**: All 17 issue-scoped cmdlets now declare `-Issue` (or `-InputObject`, where the historical name is kept) as `[AtlassianPS.JiraPS.Issue]` and use the new `[AtlassianPS.JiraPS.IssueTransformation()]` attribute to coerce the bound value at parameter binding time. Affected cmdlets: `Add-JiraIssueAttachment`, `Add-JiraIssueComment`, `Add-JiraIssueLink`, `Add-JiraIssueWatcher`, `Add-JiraIssueWorklog`, `Get-JiraIssue` (`-InputObject`), `Get-JiraIssueAttachment`, `Get-JiraIssueComment`, `Get-JiraIssueWatcher`, `Get-JiraIssueWorklog`, `Get-JiraRemoteLink`, `Invoke-JiraIssueTransition`, `Remove-JiraIssue` (`-InputObject`), `Remove-JiraIssueAttachment`, `Remove-JiraIssueWatcher`, `Remove-JiraRemoteLink`, `Set-JiraIssue`, `Set-JiraIssueLabel`.
  - The old `ValidateScript` block that accepted `[String]` or `[PSCustomObject]` with a `JiraPS.Issue` `PSTypeName` is gone. The transformer accepts: an existing `[AtlassianPS.JiraPS.Issue]`, a non-empty issue-key string (wrapped in a stub `Issue` whose `Key` is set), or a legacy `PSCustomObject` decorated with the `AtlassianPS.JiraPS.Issue` `PSTypeName` (mapped to a real `Issue` instance for backward compatibility with hand-rolled mocks). Anything else throws an `ArgumentTransformationMetadataException` at parameter binding time with an actionable error message instead of failing later inside the cmdlet body.
  - The historical "single Issue only" runtime guardrail (`if (@($Issue).Count -ne 1) { throw }`) was removed from cmdlets where pipeline iteration is the obviously-correct behaviour. Pipelines like `Get-JiraIssue -Query 'project = TEST' | Add-JiraIssueComment -Comment 'reviewed'` now run the cmdlet's `process` block once per piped issue, matching the rest of PowerShell. Passing an array to `-Issue` directly (e.g. `-Issue $array`) also iterates instead of throwing — this is a soft behaviour change for scripts that relied on the old guard to surface "you passed too many issues" mistakes.
  - `Add-JiraIssueLink` no longer self-shadows its loop variable (`foreach ($IssueLink in $IssueLink)` is now `foreach ($_issueLink in $IssueLink)`); the public surface is unchanged.
  - `Remove-JiraIssueAttachment` drops `ValueFromPipeline` from `-Issue` (it keeps `ValueFromPipelineByPropertyName`), so piping the output of `Get-JiraIssueAttachment` now binds correctly to `-AttachmentId` via the attachment object's `Id` property instead of mis-binding to `-Issue` and producing a transformation error.
- **BREAKING (soft)**: The user-scoped cmdlets that previously accepted `-User` / `-UserName` / `-Owner` / `-Assignee` / `-Reporter` as `[Object]` (or `[String]`) with a polymorphic `ValidateScript` now declare a real typed parameter and use the new `[AtlassianPS.JiraPS.UserTransformation()]` attribute to coerce the bound value at parameter binding time. Affected cmdlets:
  - `Add-JiraGroupMember` (`-UserName` → `[AtlassianPS.JiraPS.User[]]`)
  - `Find-JiraFilter` (`-Owner` → `[AtlassianPS.JiraPS.User]`)
  - `Invoke-JiraIssueTransition` (`-Assignee` → `[AtlassianPS.JiraPS.User]`)
  - `New-JiraIssue` (`-Assignee` → `[AtlassianPS.JiraPS.User]`, `-Reporter` → `[AtlassianPS.JiraPS.User]`)
  - `Remove-JiraGroupMember` (`-User` → `[AtlassianPS.JiraPS.User[]]`)
  - `Remove-JiraUser` (`-User` → `[AtlassianPS.JiraPS.User]`)
  - `Set-JiraIssue` (`-Assignee` → `[AtlassianPS.JiraPS.User]`)
  - `Set-JiraUser` (`-User` → `[AtlassianPS.JiraPS.User]`)
  The private `Resolve-JiraUser` helper switched its `-InputObject` to the same shape.
  - The transformer accepts: an existing `[AtlassianPS.JiraPS.User]`, a non-empty identifier string (a username on Data Center, an `accountId` on Cloud — the slot is stored in `Name` and `Resolve-JiraUser` inspects the pattern at call time to dispatch to `/accountId` or `/username`), or a legacy `PSCustomObject` decorated with the `AtlassianPS.JiraPS.User` `PSTypeName` (mapped to a real `User` instance for backward compatibility with hand-rolled mocks). Anything else throws an `ArgumentTransformationMetadataException` at parameter binding time with an actionable error message instead of failing later inside the cmdlet body.
  - The internal `foreach ($_user in $User) { ... }` fan-out loops in `Set-JiraUser` and `Remove-JiraUser` are gone — pipeline iteration handles arrays naturally now (`Get-JiraGroupMember -Group dev | Remove-JiraUser -Force` runs the cmdlet's `process` block once per piped user). `Remove-JiraGroupMember` keeps its `-User` array fan-out because each user has to be paired against every `-Group` in the cross-product.
  - `Find-JiraFilter -Owner` now resolves the user through `Resolve-JiraUser` (which handles the Cloud-vs-DC `accountId`/`username` dispatch consistently) instead of calling `Get-JiraUser -InputObject` directly.
  - The whitespace-only rejection messages on `Set-JiraIssue -Assignee`, `Invoke-JiraIssueTransition -Assignee`, and `New-JiraIssue -Assignee`/`-Reporter` now come from the transformer (`"Cannot bind an empty or whitespace string to a User parameter."`) instead of the old per-cmdlet `ValidateScript` blocks. The contract is unchanged — empty/whitespace strings still fail at parameter binding — only the wording differs.
- **BREAKING**: Promoted `Group` to a real .NET class under the `AtlassianPS.JiraPS.*` namespace (alongside the original eight types). The class exposes `Name [string]`, `RestUrl [string]`, `Size [int]`, and `Member [AtlassianPS.JiraPS.User[]]`. `ConvertTo-JiraGroup` now returns `[AtlassianPS.JiraPS.Group]` instances directly — `GetType().FullName` is `AtlassianPS.JiraPS.Group` and `PSObject.TypeNames[0]` is `AtlassianPS.JiraPS.Group` (was `JiraPS.Group`).
  Scripts that test `if ('JiraPS.Group' -in $obj.PSObject.TypeNames)` must switch to `'AtlassianPS.JiraPS.Group'` (or use the more idiomatic `$obj -is [AtlassianPS.JiraPS.Group]`). Mocks built as `[PSCustomObject]@{ PSTypeName = 'JiraPS.Group'; ... }` must use `'AtlassianPS.JiraPS.Group'`.
- **BREAKING (soft)**: The four group-scoped cmdlets that previously accepted `-Group` as `[Object[]]` with a polymorphic `ValidateScript` now declare a real typed parameter and use the new `[AtlassianPS.JiraPS.GroupTransformation()]` attribute to coerce the bound value at parameter binding time. Affected cmdlets:
  - `Add-JiraGroupMember` (`-Group` → `[AtlassianPS.JiraPS.Group[]]`)
  - `Get-JiraGroupMember` (`-Group` → `[AtlassianPS.JiraPS.Group[]]`)
  - `Remove-JiraGroup` (`-Group` → `[AtlassianPS.JiraPS.Group[]]`)
  - `Remove-JiraGroupMember` (`-Group` → `[AtlassianPS.JiraPS.Group[]]`)
  - The transformer accepts: an existing `[AtlassianPS.JiraPS.Group]`, a non-empty group-name string (wrapped in a stub `Group` whose `Name` is set), or a legacy `PSCustomObject` decorated with the `AtlassianPS.JiraPS.Group` (or, for backward compatibility with hand-rolled mocks, the historical `JiraPS.Group`) `PSTypeName`. Anything else throws an `ArgumentTransformationMetadataException` at parameter binding time with an actionable error message instead of failing later inside the cmdlet body.
  - Empty or whitespace-only strings now fail at parameter binding (`"Cannot bind an empty or whitespace string to a Group parameter."`) instead of silently passing through and producing an opaque server error.
- **BREAKING (soft)**: The five version-scoped cmdlets that previously accepted `-Version` / `-After` / `-InputObject` / `-InputVersion` as `[Object]`/`[Object[]]` (with a polymorphic `ValidateScript` accepting an `AtlassianPS.JiraPS.Version` PSTypeName, an `[Int]`, or a `[String]` Version name) now declare a real typed parameter and use the new `[AtlassianPS.JiraPS.VersionTransformation()]` attribute to coerce the bound value at parameter binding time. Affected cmdlets:
  - `Get-JiraVersion` (`-InputVersion` → `[AtlassianPS.JiraPS.Version]`)
  - `Move-JiraVersion` (`-Version` → `[AtlassianPS.JiraPS.Version]`, `-After` → `[AtlassianPS.JiraPS.Version]`)
  - `New-JiraVersion` (`-InputObject` → `[AtlassianPS.JiraPS.Version]`)
  - `Remove-JiraVersion` (`-Version` → `[AtlassianPS.JiraPS.Version[]]`)
  - `Set-JiraVersion` (`-Version` → `[AtlassianPS.JiraPS.Version[]]`)
  - The transformer accepts: an existing `[AtlassianPS.JiraPS.Version]`; a numeric scalar (any integer width — Jira version IDs are integral, so the value is wrapped in a stub `Version` whose `ID` is set); a non-empty string (parsed as a version ID when it looks numeric, otherwise stored in `Name` for the `New-JiraVersion -InputObject 'My Version'` shape that fell out of the previous `[Object]` parameter); or a legacy `PSCustomObject` decorated with the `AtlassianPS.JiraPS.Version` (or, for backward compatibility with hand-rolled mocks, the historical `JiraPS.Version`) `PSTypeName`.
  - Unlike the Issue/User/Group transformers, `VersionTransformation` returns the input unchanged (rather than throwing) when the value is not one of the recognized shapes. `Get-JiraVersion` has sister `ValueFromPipeline` parameter sets — notably `-InputProject [PSTypeName('AtlassianPS.JiraPS.Project')]` — and a hard transformer throw would block PowerShell's parameter-set fallthrough. Returning the value untouched lets the binder reject it cleanly and try the next set, preserving the `Get-JiraProject ... | Get-JiraVersion` pipeline.
  - Empty or whitespace-only strings still fail at parameter binding (`"Cannot bind an empty or whitespace string to a Version parameter."`).
  - The internal `if ($Version.Id) { $versionId = $Version.Id } else { $versionId = $Version }` adapter blocks in `Move-JiraVersion`, `Remove-JiraVersion`, and `Set-JiraVersion` are gone — the typed parameter is always a real `Version` instance, so the body can read `$Version.Id` directly.
  - `New-JiraVersion -InputObject` now skips `releaseDate` / `startDate` from the request body when the slot is `$null` (previously it called `.ToString('yyyy-MM-dd')` on a `$null` and produced a malformed payload), and reads the project ID from the new `Version.Project [long?]` slot instead of the legacy `Project.Key`/`Project.Id` PSObject lookup.
- **BREAKING (soft)**: The two filter-scoped cmdlets that previously accepted `-InputObject` / `-Filter` as `[Object]`/`[Object[]]` (with a polymorphic `ValidateScript` accepting an `AtlassianPS.JiraPS.Filter` PSTypeName or a `[String]` filter ID) now declare a real typed parameter and use the new `[AtlassianPS.JiraPS.FilterTransformation()]` attribute to coerce the bound value at parameter binding time. Affected cmdlets:
  - `Get-JiraFilter` (`-InputObject` → `[AtlassianPS.JiraPS.Filter[]]`)
  - `Get-JiraIssue` (`-Filter` → `[AtlassianPS.JiraPS.Filter]`)
  - The transformer accepts: an existing `[AtlassianPS.JiraPS.Filter]`; a numeric scalar (any integer width — Jira filter IDs are integral); a non-empty string (treated as a filter ID, matching the historic `Get-JiraFilter -InputObject [String]` shape that always called `.ToString()` on the value and forwarded it to `-Id`); or a legacy `PSCustomObject` decorated with the `AtlassianPS.JiraPS.Filter` (or, for backward compatibility with hand-rolled mocks, the historical `JiraPS.Filter`) `PSTypeName`.
  - Empty or whitespace-only strings now fail at parameter binding (`"Cannot bind an empty or whitespace string to a Filter parameter."`) instead of silently passing through and producing an opaque server error.
  - The `if ('AtlassianPS.JiraPS.Filter' -in $object.PSObject.TypeNames) { $thisId = $object.ID } else { $thisId = $object.ToString() }` adapter block in `Get-JiraFilter` is gone — the typed parameter is always a real `Filter` instance, so the body reads `$object.ID` directly.
  - `Get-JiraIssue -Filter` no longer round-trips through `Get-JiraFilter -InputObject`; it calls `Get-JiraFilter -Id $Filter.ID` directly.
- **BREAKING (soft)**: The four project-scoped cmdlets that previously accepted `-Project` as `[Object]`/`[Object[]]` (with a polymorphic `ValidateScript` accepting an `AtlassianPS.JiraPS.Project` PSTypeName, an `[Int]` ID, or a `[String]` project key) now declare a real typed parameter and use the new `[AtlassianPS.JiraPS.ProjectTransformation()]` attribute to coerce the bound value at parameter binding time. Affected cmdlets:
  - `Get-JiraComponent` (`-Project` → `[AtlassianPS.JiraPS.Project[]]`)
  - `Find-JiraFilter` (`-Project` → `[AtlassianPS.JiraPS.Project]`)
  - `New-JiraVersion` (`-Project` → `[AtlassianPS.JiraPS.Project]`)
  - `Set-JiraVersion` (`-Project` → `[AtlassianPS.JiraPS.Project]`)
  - The transformer accepts: an existing `[AtlassianPS.JiraPS.Project]`; a numeric scalar (any integer width — Jira project IDs are integral on the wire, so the value is wrapped in a stub `Project` whose `ID` is set); a non-empty string (treated as a project key, matching the historic call-site contract that forwarded the raw value to `Get-JiraProject -Project` or to `/project/{idOrKey}` URLs); or a legacy `PSCustomObject` decorated with the `AtlassianPS.JiraPS.Project` (or, for backward compatibility with hand-rolled mocks, the historical `JiraPS.Project`) `PSTypeName`.
  - Empty or whitespace-only strings now fail at parameter binding (`"Cannot bind an empty or whitespace string to a Project parameter."`) instead of silently passing through and producing an opaque server error.
  - The internal `if ($Project.Id) { ... } else { Get-JiraProject -Project $Project }` adapter blocks in `Find-JiraFilter`, `New-JiraVersion`, and `Set-JiraVersion` are gone — the typed parameter is always a real `Project` instance, so the body reads `$Project.Id` / `$Project.Key` directly. `New-JiraVersion` and `Set-JiraVersion` prefer `projectId` (when the numeric ID is known) and fall back to the v2/v3 `project` field (which accepts the project key) when only the key is bound.
  - `Get-JiraComponent -Project` reads `$_project.Key` (or `$_project.ID` when only an ID was bound) and inlines it into the `/project/{idOrKey}/components` URL — no separate `Get-JiraProject` round-trip.

### Added

- Added a single string-arg convenience constructor to the six identifier-driven `AtlassianPS.JiraPS.*` classes — `Issue(string key)`, `User(string identifier)`, `Project(string key)`, `Group(string name)`, `Filter(string id)`, and `Version(string nameOrId)` — for the recurring stub-from-an-identifier case (`[AtlassianPS.JiraPS.Issue]::new('TEST-1')` instead of `[AtlassianPS.JiraPS.Issue]@{ Key = 'TEST-1' }`).
  Each ctor's routing is identical to the matching `*TransformationAttribute` so a value built via `::new()` and a value bound via `-Parameter <string>` produce the same stub: the `User` ctor stores the input in `Name`, `Version` stores numeric tokens in `ID` and falls back to `Name` for the rest, etc. Null / empty / whitespace input throws an `ArgumentException` at construction, matching the transformers' "no silent garbage" contract.
  Each class also gains an explicit parameterless ctor (`public Foo() {}`) so the existing `[AtlassianPS.JiraPS.Foo]@{ ... }` hashtable-cast pattern keeps working — declaring a parameterized ctor in C# removes the implicit default, which the 30+ existing call sites depend on; a regression test locks the parameterless ctor into place. `Comment`, `Session`, and `ServerInfo` are intentionally untouched (they are not stub-typical). The transformer bodies were reworked to use the new ctors at their stub-construction sites for symmetry with the public surface.
- **Compiled types at import (`Add-Type`)**: Maintainer and host-operator notes. The `AtlassianPS.JiraPS.*` classes compile from `JiraPS/Types/AtlassianPS.JiraPS.cs` on the **first** `Import-Module` in a session (`JiraPS.psm1`, `#region Dependencies`); a type-presence guard keeps re-imports cheap. **Cold start** pays a small one-time compile cost. **Locked-down hosts** that block just-in-time compilation, or deployments that omit the `.cs` file from the module layout, can fail to load the module. The source must remain compatible with **Windows PowerShell 5.1's bundled CodeDOM compiler (C# 5 only)** — avoid C# 6+ syntax (e.g. `nameof`, interpolated strings, `is Type x` pattern variables) unless the load path is switched to a Roslyn-based compile. **Argument transformers**: when a parameter competes with another pipeline parameter set, return the input unchanged for unrecognized shapes instead of throwing; see `AGENTS.md` → *Argument transformation attributes*.
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

- Reorganised the integration test workflows. The Cloud `Smoke` job moved from `.github/workflows/integration_tests.yml` into the standard `ci.yml` pipeline, where it runs on every first-party PR and every push to `master` and (via the existing `CI Result` aggregator + `release.yml`'s `workflow_conclusion: success` requirement) gates publishing to PSGallery. The remaining full Cloud suite was merged with the new Server (Data Center) job into a single `integration_tests.yml` workflow with two parallel jobs (`cloud_integration_tests`, `server_integration_tests`) running on a shared nightly cron + manual dispatch (with an optional `track` input to dispatch one or both); the standalone `jira_server_ci.yml` was removed. The `run-integration-tests` PR label opt-in is retired — operators dispatch the full Cloud suite via the Actions tab's "Run workflow" button instead.
- Added private helper `Resolve-JiraTextFieldPayload` that returns either the input string (Server / Data Center) or an Atlassian Document Format hashtable (Cloud) for rich-text fields, and warns when wiki-markup table syntax is detected on Cloud. Used by `Add-JiraIssueComment`, `Add-JiraIssueWorklog`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, and `Set-JiraIssue` to centralise the Cloud-vs-DC payload-shape decision in one place. (#602)
- Added private helper `ConvertTo-JiraRestApiV3Url` that rewrites `/rest/api/2/...` URLs (typically built from a `JiraPS.Issue.RestUrl` value Jira Cloud returns as v2 even on Cloud) to their `/rest/api/3/...` equivalents on Cloud, leaving Server / Data Center URLs untouched. Used by `Add-JiraIssueComment`, `Add-JiraIssueWorklog`, `Invoke-JiraIssueTransition`, `New-JiraIssue`, and `Set-JiraIssue` to dispatch their writes to the correct API version so ADF payloads are accepted on Cloud. (#602)
- Added private helper `Test-JiraRichTextField` that inspects a `JiraPS.Field` schema (`schema.type -eq 'doc'`, `schema.system in ('description','environment')`, or `schema.custom` of `...customfieldtypes:textarea`) to decide whether a value supplied via `-Fields` requires ADF wrapping on Jira Cloud. Falls back to the system-field id list (`description`, `environment`) when no schema is available. Used by `New-JiraIssue`, `Set-JiraIssue`, and `Invoke-JiraIssueTransition` so hashtable-supplied rich-text fields go through `Resolve-JiraTextFieldPayload` on Cloud, matching the behaviour of the explicit `-Description` / `-AddComment` / `-Comment` parameters. (#602)
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
  - Replaced `Get-Member -MemberType *Property` lookups with direct `PSObject.Properties` access in `ConvertTo-JiraTable`, `Add-JiraIssueLink`, `Remove-JiraIssueLink`, `Resolve-JiraError`, `Expand-Result`, `ConvertTo-JiraCreateMetaField`, and `ConvertTo-JiraEditMetaField`.
- Extracted user-reference payload construction into a private `Resolve-JiraUserPayload` helper shared by `Set-JiraIssue`, `Invoke-JiraIssueTransition`, and `New-JiraIssue` (and reusable for any future cmdlet that needs to point at a Jira user — assignee, reporter, etc.). As a side-effect, `Invoke-JiraIssueTransition -Unassign` on Jira Cloud now correctly emits `{accountId: null}` instead of `{name: ""}`. The helper also throws explicitly when handed a Cloud user object that has no `AccountId`, instead of silently emitting an unassign payload.
- `New-JiraIssue -Reporter` now resolves the user via `Resolve-JiraUser` on Jira Server / Data Center too (previously only resolved on Jira Cloud). Typo'd usernames are now caught client-side instead of producing an opaque server error from the create endpoint.
- Hardened the integration test harness's `New-TemporaryTestIssue` helper (in `Tests/Helpers/IntegrationTestTools.ps1`) to probe `Get-JiraIssueCreateMetadata` for the chosen project / issue type and auto-supply any required field that lacks a `HasDefaultValue` flag (Reporter -> current authenticated user, fields with `AllowedValues` -> first allowed value, schema-typed fields -> a sane default per type). Refactored every `Server`-tagged integration test's `BeforeAll` (`Attachments`, `Comments`, `IssueLinks`, `Remove-JiraIssue`, `Server`, `Set-JiraIssue`, `Transitions`, `Worklogs`) and the new-test template (`.template.ps1`) to mint temporary issues through the helper instead of calling `New-JiraIssue` directly. Closes the BeforeAll-cascade failure cluster on the Server CI track where the moveworkforward `jira-core-task-management` template's tighter field configuration tripped a bare create call. The probe-and-fill logic was then extracted into a standalone `Get-MinimumValidIssueParameter` helper and `Tests/Integration/New-JiraIssue.Integration.Tests.ps1` (`Basic Issue Creation > creates a new issue with required fields`, `creates an issue with description`, `returns an issue with correct type`; `Issue Types > creates a Task`; `Custom Fields > accepts additional fields via -Fields parameter`) was refactored to splat the helper's output into its own bare `New-JiraIssue` calls — those tests previously assumed the Cloud baseline (where Project / IssueType / Summary suffices) and threw `ParameterValue.CreateMetaFailure` on Server before the request ever left the box. The helper is a pure read-only probe so the New-JiraIssue tests still exercise the cmdlet end-to-end (POST included).
- Renamed the `TestIntegration` task's NUnit output from `IntegrationTests.xml` to `Test-Integration.xml` so the integration-test artifact matches the existing `Test*.xml` `.gitignore` pattern alongside the unit-test results (`Test-<OS>-<PSVersion>.xml`). Updated the matching `path:` references in `.github/workflows/ci.yml` (`Smoke-Tests` artifact) and `.github/workflows/integration_tests.yml` (`Cloud-Integration-Tests` and `Server-Integration-Tests` artifacts), and the `Tests/Integration/README.md` artifact description. Without the rename, a local `Invoke-Build -Task TestIntegration` run left an untracked `IntegrationTests.xml` at the repo root that `git status` surfaced.

### Fixed

- Fixed `Tests/Integration/Search.Integration.Tests.ps1` `JQL with Operators > supports OR operator`. The previous JQL joined the live test project against a literal `NONEXISTENT` project key to prove the OR branch was actually evaluated. Jira Data Center's JQL parser rejects unknown project keys outright with HTTP 400 (Cloud silently drops the unknown clause), so `-ErrorAction Stop` blew up before the assertion ran. The intermediate iteration switched to `summary ~ "JiraPS-IntTest" OR created >= -7d`, which worked on Server (Wait-JiraServer.ps1 seeds a baseline issue carrying the prefix) but flapped on Cloud against the long-lived test project where no recent issues had been created and no summary matched the prefix. The current query anchors one OR branch to `key = $JIRA_TEST_ISSUE` (the test issue is guaranteed to be in the test project on both tracks) and the other to `created >= -90d` (a wider window so both halves of the OR exercise real data on Cloud). The union always matches at least the baseline issue.
- Fixed `Tests/Integration/Versions.Integration.Tests.ps1` `Remove-JiraVersion > Version Deletion > deletes a version` racing against the version backend on Jira Data Center. The earliest assertion called `Get-JiraVersion -Project -Name` immediately after the DELETE; the embedded H2 store the moveworkforward AMPS image runs against does not always reflect the cascade in time for that read, so the listing occasionally returned the just-deleted version (false negative). The next iteration switched to `Get-JiraVersion -Id $version.Id | Should -Throw`, then to a 30 s poll on the by-ID endpoint accepting either a 404 or an empty payload — both of which still flapped because the AMPS H2 store keeps answering the by-ID GET successfully out of an in-memory cache for well over 30 s after the DELETE commits (CI run [#24935398326](https://github.com/AtlassianPS/JiraPS/actions/runs/24935398326) burned the full 30 s window on every iteration of the loop without the cached payload ever changing). The current assertion polls the project-scoped `/rest/api/2/project/{key}/versions` endpoint instead, which is regenerated from the project's canonical version table on every request and reflects the delete on the very next read on both Cloud and Server. The poll is therefore back to a tight 15 s budget that typically completes on the first iteration, with the wider window reserved for any one-off lag. (`Get-JiraVersion -Id` is intentionally avoided here because it is the wrong source of truth for "is this version still reachable" given the cache behaviour.)
- Fixed `Tests/Integration/Filters.Integration.Tests.ps1` `Find-JiraFilter` tests (`searches for filters by name`, `retrieves my filters`) which both depended on the authenticated account already owning at least one saved filter — true for the long-lived Cloud test account, false for a freshly-booted Data Center container. The `Filters` `BeforeAll` now seeds one filter via `New-JiraFilter -Favorite` (named with the standard `JiraPS-IntTest-Filter-…` prefix so it's both discoverable by the `-Name "test"` substring search and reapable by `Remove-StaleTestResource`; `-Favorite` ensures the bare `Find-JiraFilter` "my filters" call surfaces it on Server, where the `/rest/api/2/filter/search` endpoint scopes the no-arg result set to the caller's favourites), then polls `Find-JiraFilter` for up to 15 s to confirm the filter has landed in the Lucene-backed search index before letting the dependent tests proceed. If the seed never becomes searchable in that window the seed is nulled out and the two dependent assertions self-skip with a clear message.
- Fixed `Tests/Integration/Transitions.Integration.Tests.ps1` `Invoke-JiraIssueTransition > Transition Cycle > completes a full transition cycle (To Do -> In Progress -> To Do)`. The previous incarnation hardcoded the Cloud Software default workflow's status names in the test name, picked `$availableTransitions[0]` blindly, and asserted that the post-transition status differed from the initial one — a logic bug because nothing forced the chosen transition to actually change state. On the moveworkforward AMPS image's auto-provisioned `jira-core` workflow, `[0]` is sometimes a self-loop or a guarded conditional that resolves back to the current status on a freshly-created issue, so the assertion failed silently as a no-op. Renamed the test, switched to runtime discovery of transitions via the `JiraPS.Transition.ResultStatus.Name` field exposed by `ConvertTo-JiraTransition`, filtered to the subset of transitions whose destination differs from the current status, asserted the post-transition status equals the discovered destination (instead of the weaker `-Not -Be $initialStatus`), added `-ErrorAction Stop` so silent transition failures surface, and tried to round-trip back to the original status when a true reverse edge exists (falling back to any state-changing transition for linear workflows like `Open -> In Progress -> Resolved`). Also corrected two related bugs the first iteration introduced: (1) `JiraPS.Issue.Status` is flattened to a plain string by `ConvertTo-JiraIssue` (it stores `$i.fields.status.name`), so the test now compares `$issue.Status` directly instead of dereferencing a non-existent `.Status.Name` (the destination state of a `JiraPS.Transition`, however, IS exposed as a nested object — that side of the comparison is unchanged); (2) added a 10 s poll on the post-transition `Get-JiraIssue` call to absorb the brief moment AMPS standalone serves a stale issue snapshot from cache after the transition POST returns 204.
- Fixed `Tests/Integration/Transitions.Integration.Tests.ps1` `Invoke-JiraIssueTransition > Transition Operations > transitions with a comment` flapping when prior transition tests in the same Context had added their own audit-log comments to the shared `$transitionIssue`. The assertion called `Get-JiraIssueComment | Select -Last 1` and pattern-matched on the literal text `Transition comment`, but Jira Server orders comments by `created` and identical timestamps can swap the read-back order against the write order, so `-Last 1` occasionally returned a sibling test's comment whose `Body` matched the regex but didn't carry our specific transition payload. The assertion now embeds a fresh `[guid]::NewGuid()` marker into the comment text, then searches *all* comments for that exact marker — race-free and immune to comment ordering quirks. Also added `-ErrorAction Stop` to surface silent transition failures and a poll (now 30 s, raised from the original 15 s after CI run [#24935398326](https://github.com/AtlassianPS/JiraPS/actions/runs/24935398326) showed the marker still not landed within the original window) on `Get-JiraIssueComment` because AMPS standalone persists the comment in the post-transition phase of the workflow executor (after the 204 returns), so an immediate read can race ahead of the comment store commit.
- Bumped the `Server Integration Tests (Dockerized Jira DC)` job's `timeout-minutes` from 30 to 60 in `.github/workflows/integration_tests.yml`. The 30 min cap ran out mid-suite (see CI run [#24927584306](https://github.com/AtlassianPS/JiraPS/actions/runs/24927584306)): the cold-boot Docker image pull + AMPS Maven dep verification + Tomcat startup ate ~10 min, then the parallel Pester runner (`ThrottleLimit=4`) ate the remaining ~20 min before being killed, leaving ~half of the Server-tagged suite unreported. Each test's per-issue/per-version provisioning round-trip is gated on Lucene reindex commits inside the embedded Jira and is the dominant runtime cost; sharding workers across multiple containers would help further but is overkill for now. The 60 min cap leaves a comfortable ~40-45 min margin for the Pester run on cold-boot CI runs while still surfacing genuine hangs (the runner kills well before GitHub Actions' 6 hr hard ceiling).
- Added a 25 min `timeout-minutes` to the `Run full Server-tagged integration suite` step in `.github/workflows/integration_tests.yml`, separate from the job-level 60 min cap. CI run [#24935398326](https://github.com/AtlassianPS/JiraPS/actions/runs/24935398326) showed the parallel test runner (`Tests/Invoke-ParallelPester.ps1`, `ForEach-Object -Parallel`) producing the last per-file `Tests Passed: 10, Failed: 1, Skipped: 1` line at 16:37:44 UTC and then hanging for ~53 min before the job-level timeout cancelled the workflow at 17:30:20 — long enough that neither the orchestrator's `========== TEST SUMMARY ==========` block nor the merged-NUnit XML write block ran, so the artifact-upload + container-teardown steps (gated on `if: always()`) only got a chance to run once GitHub Actions force-killed the step. Capping the step at 25 min gives an honest budget for the actual Pester work (boot is already done in the previous step, the suite reliably completes in <10 min) while killing the orchestrator promptly when `ForEach-Object -Parallel` refuses to wind down — that frees up ~30+ min for the post-step artifact upload and teardown so the `jira-container.log` / `Test-Integration.xml` artifacts land on a hung run too, and surfaces real hangs in <30 min instead of ~1 hr. The job-level 60 min cap stays as the outer safety net for the boot + provisioning + Pester sequence as a whole.
- Improved the error message of `New-JiraIssue` when Jira's createmeta marks a field as `required: true` without `hasDefaultValue: true` and the caller omits it. The previous `ArgumentException.Message` was the unhelpful generic `"Invalid or missing value Parameter"`, with the actual field name + id + project + issuetype context tucked away in `ErrorRecord.ErrorDetails` (which Pester, `Write-Error`, and most logging surfaces don't print). The new message embeds the field descriptor — `"Invalid or missing value for required field [<Name>] (id=[<Id>]) on project [<Project>] / issuetype [<IssueType>]. The field is marked required by Jira's createmeta and has no server-side default; supply it via the matching parameter or via -Fields. Use Get-JiraIssueCreateMetadata for more information."` — directly into the `Exception.Message` so the cause is visible in every standard error surface. Existing unit tests (which `Should -Throw -ExpectedMessage "*Invalid or missing value*"`) continue to pass; the `ErrorDetails` block is unchanged.
- Fixed read-cmdlet integration tests that asserted `Should -BeOfType [PSCustomObject]` on results that legitimately come back `$null` against a freshly-provisioned Data Center deployment (the Cloud track has historically shielded these from view because the long-lived Cloud project always carries leftover data). Each affected `It` block now asserts that the call itself succeeds and only type-checks the payload when there is data to inspect; the dedicated typed-shape assertion in the sibling `It` block continues to cover the populated case (often via a Add+Get round-trip from the same file). Affected tests:
  - `Tests/Integration/Comments.Integration.Tests.ps1` -> `Get-JiraIssueComment > Reading Comments > retrieves comments from an issue`.
  - `Tests/Integration/Attachments.Integration.Tests.ps1` -> `Get-JiraIssueAttachment > Attachment Retrieval > retrieves attachments from an issue`.
  - `Tests/Integration/Projects.Integration.Tests.ps1` -> `Get-JiraComponent > Project Components > retrieves components for a project`.
  - `Tests/Integration/Versions.Integration.Tests.ps1` -> `Get-JiraVersion > Project Versions > retrieves versions for a project`.
  - `Tests/Integration/Metadata.Integration.Tests.ps1` -> `Get-JiraField > Field Retrieval > includes custom fields` (now `Set-ItResult -Skipped` when the deployment has no customfields configured, which is the default state of the AMPS standalone Jira Software image).
- Fixed two latent bugs in `Tests/Integration/IssueLinks.Integration.Tests.ps1` that were silently failing on every deployment (Cloud and Server alike):
  - The `link types have Id, Name, Inward, and Outward properties` test asserted on `InwardDescription` / `OutwardDescription`, but `ConvertTo-JiraIssueLinkType` exposes those labels as `InwardText` / `OutwardText`. The assertion always saw `$null` and only ever passed because Cloud surfaced the failure under a different cluster. Renamed both references to the actual property names; the unit test (`ConvertTo-JiraIssueLinkType.Unit.Tests.ps1`) is the canonical contract here.
  - The `retrieves a specific link type by ID` test passed `$firstType.Id` (a `[string]`) to `Get-JiraIssueLinkType -LinkType`, which only routes through `/rest/api/2/issueLinkType/{id}` when the argument is `[Int]`; strings fall into the by-name lookup and return `$null`. Coerced the argument to `[int]` so the test exercises the documented ID branch on both Cloud and Data Center.
- Fixed `New-JiraIssue` rejecting valid create payloads when the project's createmeta marked a field as `required: true` while it also advertised `hasDefaultValue: true`. The Jira REST API guarantees the server populates such fields from their configured default when the caller omits them (this is what the Jira UI relies on for fields like Reporter -> acting user, Priority -> project default, etc.), so refusing to send the request was both wrong and made the cmdlet unusable on stricter project field configurations. The validator now only errors out for required fields that have no server-side default to fall back on, and the error message has been clarified to say so. Existing behavior for `Required = $true / HasDefaultValue = $false` is unchanged.
- Fixed `New-JiraIssue`, `Set-JiraIssue`, and `Invoke-JiraIssueTransition` rejecting rich-text fields (e.g. `description`, `environment`, multi-line custom-field text-areas) supplied via `-Fields` on Jira Cloud. Cloud's v3 issue endpoints (which JiraPS now targets so ADF is accepted) reject raw strings for these fields with `"Operation value must be an Atlassian Document"`. The `-Fields` processing loop now consults the field's schema via the new `Test-JiraRichTextField` helper and routes string values for rich-text fields through `Resolve-JiraTextFieldPayload`, matching the behaviour of the explicit `-Description`, `-AddComment`, and `-Comment` parameters. Server / Data Center, and non-rich-text fields on Cloud, are unaffected. (#602)
- **BREAKING (soft)**: Fixed `JiraPS.Issue.Status` only surfacing the bare status name string, so `$issue.Status.Name` always evaluated to `$null` and downstream code could not inspect the status category, icon, or REST URL. `ConvertTo-JiraIssue` now converts the field through `ConvertTo-JiraStatus`, returning a proper `JiraPS.Status` object that exposes `Id`, `Name`, `Description`, `IconUrl`, and `RestUrl`. The object's `ToString()` still renders the status name, so `"$($issue.Status)"`, `Write-Output $issue.Status`, and the default formatter continue to display the previous text. Equality comparisons against the bare status name (`$issue.Status -eq 'Open'`) need to be updated to `$issue.Status.Name -eq 'Open'`. See [`about_JiraPS_MigrationV3`](https://atlassianps.org/docs/JiraPS/about/migration-v3.html) for migration examples. (#634)
- Fixed `Get-JiraIssue` prompting for input when piping JiraPS.Issue objects (added `ValueFromPipelineByPropertyName` to `-Key` parameter)
- Fixed long-standing typo in `Invoke-JiraIssueTransition` where the transition-cast error path constructed its `ErrorRecord` against an undefined `$errorTargetError` variable instead of `$errorTarget`.
- Fixed `ConvertTo-GetParameter` returning `'?'` for an empty hashtable; it now returns `''` again, matching its prior contract and preventing accidental trailing `?` in URLs.
- Fixed `ConvertTo-GetParameter` not URL-encoding query keys or values, so any value containing a reserved URI character (space, `&`, `=`, `?`, `#`, `+`, `%`, non-ASCII, ...) produced a malformed or silently-wrong query string.
  Example: a group named `"Dev & QA"` previously serialised as `?groupname=Dev & QA&maxResults=50`, which the server parsed as three separate parameters; it now serialises as `?groupname=Dev+%26+QA&maxResults=50`.
  The companion parser `ConvertTo-ParameterHash` now URL-decodes both halves and splits each pair on the first `=` only, so values that legitimately contain `=` (base64 tokens, JQL fragments such as `project=TEST`) are no longer truncated.
  Callers must now pass **raw** values into the `GetParameter` hashtable; the manual `ConvertTo-URLEncoded $Query` workaround on `Get-JiraIssue -Query` has been removed accordingly.
  This also unblocks `Get-JiraGroupMember`, `Find-JiraFilter`, `Get-JiraVersion`, and other cmdlets that previously sent unescaped group names, sort fields, and JQL fragments through to Jira.
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
