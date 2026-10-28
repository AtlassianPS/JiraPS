---
locale: en-US
layout: documentation
online version: https://atlassianps.org/docs/JiraPS/about/migration-v3.html
Module Name: JiraPS
permalink: /docs/JiraPS/about/migration-v3.html
---
# JiraPS

## about_JiraPS_MigrationV3

# SHORT DESCRIPTION

This document describes the breaking changes in JiraPS v3 and how to migrate your scripts from v2.x.

# LONG DESCRIPTION

JiraPS v3 removes a number of long-deprecated parameters and "magic string" values that have been in the codebase for several major versions.
The minimum supported PowerShell version was also raised to 5.1, allowing the module to adopt newer language features and improve performance.

This guide lists every breaking change introduced in v3 and shows how to update your scripts.

## Summary of breaking changes

| Area                         | What Changed                                                            |
| ---------------------------- | ----------------------------------------------------------------------- |
| `Get-JiraIssue`              | Removed `-StartIndex`, `-MaxResults`. Use `-Skip`, `-First`.            |
| `Get-JiraGroupMember`        | Removed `-StartIndex`, `-MaxResults`. Use `-Skip`, `-First`.            |
| `Set-JiraIssue -Assignee`    | No longer accepts `'Unassigned'` or `'Default'` magic strings.          |
| `Set-JiraIssue -Assignee`    | No longer accepts `$null` or empty string. Use `-Unassign`.             |
| `Set-JiraIssue`              | New `-Unassign` switch (parameter set).                                 |
| `Set-JiraIssue`              | `-Assignee`, `-Unassign`, `-UseDefaultAssignee` are mutually exclusive. |
| `Invoke-JiraIssueTransition` | `-Assignee` no longer accepts `'Unassigned'` magic string.              |
| `Invoke-JiraIssueTransition` | `-Assignee` no longer accepts `$null` or empty string. Use `-Unassign`. |
| `Invoke-JiraIssueTransition` | New `-Unassign` switch (parameter set).                                 |
| `Set-JiraIssue -Assignee`    | No longer positional; must be supplied by name.                         |
| `New-JiraIssue -Reporter`    | No longer accepts `$null`, empty, or whitespace-only strings.           |
| `New-JiraIssue -Reporter`    | Now resolves the user via `Resolve-JiraUser` on Server / DC too.        |
| `Invoke-JiraMethod -Uri`     | Relative endpoint paths are now first-class (`/rest/api/...`).          |
| Issue `Status`              | Now an `AtlassianPS.JiraPS.Status` object instead of the bare status name string.    |
| PSTypeName rename            | Eight core types moved from `JiraPS.<Type>` to `AtlassianPS.JiraPS.<Type>`. |
| Class slot type tightening   | Boolean / numeric slots on `Filter` and `Version` are now strongly typed; missing flags surface as `$false` instead of `$null`. |
| `Version.StartDate` / `Version.ReleaseDate` | Empty-string sentinel for missing dates dropped; the slots are now `[DateTime?]` and `$null` when absent. |
| Identifier equality on core classes | `Issue`, `User`, `Project`, `Group`, `Filter`, and `Version` now compare by canonical identifier instead of object reference. |
| Issue-scoped cmdlets         | `-Issue` uses strongly typed issue objects with a custom transformer; supported arrays and pipelines iterate the `process` block per item instead of throwing. |
| User-scoped cmdlets          | `-User` on `Set-JiraUser`, `Remove-JiraUser`, `Add-JiraGroupMember`, and `Remove-JiraGroupMember`, and `-Owner` on `Find-JiraFilter`, use strongly typed `[AtlassianPS.JiraPS.User]` / `[AtlassianPS.JiraPS.User[]]` with a custom transformer. |
| Group promoted to .NET class | `Group` joins the eight original `AtlassianPS.JiraPS.*` types. `ConvertTo-JiraGroup` returns `[AtlassianPS.JiraPS.Group]`; `PSObject.TypeNames[0]` is `AtlassianPS.JiraPS.Group` (was `JiraPS.Group`). |
| Group-scoped cmdlets         | `-Group` on `Add-JiraGroupMember`, `Get-JiraGroupMember`, `Remove-JiraGroup`, and `Remove-JiraGroupMember` is now strongly-typed `[AtlassianPS.JiraPS.Group[]]` with a custom transformer. |
| Version-scoped cmdlets       | `-Version` on `Get-JiraVersion`, `Move-JiraVersion`, `Remove-JiraVersion`, and `Set-JiraVersion`, `-After` on `Move-JiraVersion`, and `-InputObject` on `New-JiraVersion` use strongly typed version objects with a custom transformer. |
| Filter-scoped cmdlets        | `-Filter` on `Get-JiraFilter` and `Get-JiraIssue` uses strongly typed `[AtlassianPS.JiraPS.Filter]` / `[AtlassianPS.JiraPS.Filter[]]` with a custom transformer. |
| Project-scoped cmdlets       | `-Project` on `Get-JiraComponent`, `Find-JiraFilter`, `New-JiraVersion`, and `Set-JiraVersion` is now strongly-typed `[AtlassianPS.JiraPS.Project]` / `[AtlassianPS.JiraPS.Project[]]` with a custom transformer. |
| Class construction           | The six identifier-driven `AtlassianPS.JiraPS.*` classes ship a single string-arg constructor for stub-from-an-identifier (`[AtlassianPS.JiraPS.Issue]::new('TEST-1')`). The hashtable-cast form `[AtlassianPS.JiraPS.Issue]@{ Key = 'TEST-1' }` continues to work. |
| Rich-text fields (read)      | On Cloud, returned as Markdown strings instead of ADF JSON trees.       |
| Rich-text fields (write)     | On Cloud, plain strings / Markdown are accepted and wrapped in ADF (previously rejected). |
| Minimum PowerShell version   | Raised from 3.0 to 5.1.                                                 |
| Issue `Assignee` | Unassigned issues return `$null` instead of `Unassigned`. |
| Nested issue and related data | History, visibility, schemas, filter subscriptions and other nested values use typed .NET objects. |
| Enum properties | Known values use nullable enums; unknown API values become `$null`. Cast to `[string]` when exporting enum names as JSON. |
| Project `Roles` and user `AvatarUrl` | These properties use dictionaries of URI values. Read entries by key. |
| Filter and related object parameters | Commands declare the object types they accept. Identifier and name shorthand remain available where documented. |

## Removed legacy commands

`Format-Jira`, the session commands and the Jira-specific server configuration commands are removed in v3.
Use `ConvertTo-JiraTable`, shared named endpoint profiles and the live connection commands below.

## Detailed migration guide

### Connections and authentication

```powershell
# v2
Set-JiraConfigServer 'https://jira.example.com'
New-JiraSession -Credential $credential
Get-JiraIssue -Key PROJ-1 -Credential $credential

# v3
$work = Connect-Jira -Name work -Uri 'https://jira.example.com' -Credential $credential
Get-JiraIssue -Issue PROJ-1 -Connection $work
Get-JiraConnection -Name work
Select-JiraConnection -Connection $work
Disconnect-Jira -Connection $work
```

Ordinary Jira commands accept `Connection` and otherwise use the selected Jira default.
Authentication belongs to connection creation; the per-call `Credential` and `Session` parameters are removed.
Use `Add-AtlassianServerConfiguration` for saved endpoints and `Connect-Jira -Profile` to connect explicitly.
No command imports the installed module's legacy `server_config` automatically.
For standalone REST work, `Invoke-JiraMethod` accepts `BaseUri` and authentication in the same call.

### Exact selectors, search and paging

```powershell
Get-JiraIssue -Issue 'PROJ-1', 'PROJ-2'
Get-JiraFilter -Filter 12345
Get-JiraVersion -Version 10001
Get-JiraVersion -Project PROJ -Name 'v3*', 'v4*' -Skip 1 -First 5
Get-JiraUser -User 'opaque-account-id' -Connection $cloud
Get-JiraUser -User 'username' -Connection $dataCenter
Get-JiraUser -Query 'John Smith' -First 10
Get-JiraUser -All -First 100
Get-JiraIssueComment -Issue PROJ-1 -Skip 5 -First 10 -PageSize 25
Get-JiraIssueWorklog -Issue PROJ-1 -Skip 5 -First 10 -PageSize 25
```

User strings are exact Cloud account IDs or Data Center usernames; display names require an explicit search.
Cloud search returns active users among the first 1,000 matches; `All` includes inactive and previously deleted accounts.
Data Center enumeration follows `/user/list` cursors when that endpoint is supported and fails actionably otherwise.
`Find-JiraFilter` uses Cloud's filter-search API; Data Center callers use exact or favorite filter lookup.
Use `User` for group membership, `Watcher` for watchers, `IssueLink` for issue links and `Link` for remote links.

### Refreshing cached metadata

Replace `-Force` with `-Refresh` in `Get-JiraField`, `Get-JiraIssueType`, `Get-JiraPriority` and `Get-JiraServerInformation`.
`-Refresh` fetches fresh data and replaces the selected connection's cached response.

```powershell
# v2
Get-JiraField -Force

# v3
Get-JiraField -Refresh
```

### Mutation intent and outputs

```powershell
Invoke-JiraIssueTransition -Issue PROJ-1 -Transition 'Start Progress' -WhatIf
Move-JiraVersion -Version 10001 -Position Last -WhatIf
Remove-JiraIssue -Issue PROJ-1 -Confirm:$false
Set-JiraIssue -Issue PROJ-1 -Description '' -Label @() -FixVersion @()
Set-JiraFilter -Filter 12345 -Name 'Review' -PassThru
$permissions = Get-JiraFilterPermission -Filter 12345
Remove-JiraFilterPermission -Filter 12345 -Permission $permissions[0]
Remove-JiraFilterPermission -Filter 12345 -All
```

Use `Confirm:$false` instead of confirmation-only `Force` switches.
`Get/Add-JiraFilterPermission` return permission records.
`All` fetches current filter permissions before removing them; omission does not imply bulk removal.
`Set-JiraFilter -PassThru` returns the successful update response without an extra lookup.
Explicitly empty description, label and fix-version inputs clear those fields; omission preserves them.
Transitions and version moves support standard confirmation and `WhatIf`.

### Saving attachments and creating users

```powershell
Get-JiraIssueAttachment -Issue PROJ-1 | Save-JiraIssueAttachment -Path './downloads'
$attachment | Save-JiraIssueAttachment -Path './report.bin' -Force
New-JiraUser -EmailAddress 'me@example.com' -Products jira-software -Connection $cloud
New-JiraUser -EmailAddress 'me@example.com' -Products @() -Connection $cloud
New-JiraUser -EmailAddress 'me@example.com' -UserName me -Connection $dataCenter
```

`Save-JiraIssueAttachment` replaces `Get-JiraIssueAttachmentFile` and returns `FileInfo` for each completed write.
The destination directory must exist; an explicit file destination accepts one attachment.
`Force` permits overwriting a file, while `WhatIf` performs no download or write.
Cloud user creation requires an explicit product-access list, including an empty array for no access.
Data Center requires a username and accepts an optional display name.
The unsupported Boolean `Notify` parameter is removed.
Manage Cloud account-field updates through Atlassian account administration.

### Pagination — `Get-JiraIssue` and `Get-JiraGroupMember`

The legacy parameters `-StartIndex` and `-MaxResults` have been removed in favor of the standard PowerShell paging parameters `-Skip` and `-First`, which were already supported in v2.

#### v2

```powershell
Get-JiraIssue -Query 'project = TEST' -StartIndex 10 -MaxResults 50
Get-JiraGroupMember -Group 'jira-users' -StartIndex 0 -MaxResults 100
```

#### v3

```powershell
Get-JiraIssue -Query 'project = TEST' -Skip 10 -First 50
Get-JiraGroupMember -Group 'jira-users' -First 100
```

### Unassigning an issue with `Set-JiraIssue`

Previously, `'Unassigned'` was a magic string and `$null` was the documented way to unassign.
Both are removed in favor of the explicit `-Unassign` switch, which is more discoverable, symmetric with `-UseDefaultAssignee`, and prevents easy mistakes such as passing a variable that is unexpectedly `$null`.

#### v2

```powershell
Set-JiraIssue -Issue TEST-01 -Assignee 'Unassigned'
Set-JiraIssue -Issue TEST-01 -Assignee $null
```

#### v3

```powershell
Set-JiraIssue -Issue TEST-01 -Unassign
```

### Default assignee with `Set-JiraIssue`

The string value `'Default'` is no longer recognised by `-Assignee`.
Use the `-UseDefaultAssignee` switch (introduced as the canonical replacement).

#### v2

```powershell
Set-JiraIssue -Issue TEST-01 -Assignee 'Default'
```

#### v3

```powershell
Set-JiraIssue -Issue TEST-01 -UseDefaultAssignee
```

### Unassigning during a transition with `Invoke-JiraIssueTransition`

Same change as `Set-JiraIssue`: the `'Unassigned'` magic string and the `$null` convention have been replaced by the explicit `-Unassign` switch.

#### v2

```powershell
Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Assignee 'Unassigned'
Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Assignee $null
```

#### v3

```powershell
Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Unassign
```

### Mutually exclusive assignee operations

In v3 the assignee-related parameters live in distinct parameter sets, so PowerShell will refuse to bind more than one of them in the same call.
PowerShell rejects conflicting parameters during parameter binding.

#### Invalid in v3

```powershell
Set-JiraIssue -Issue TEST-01 -Assignee 'alice' -Unassign            # error
Set-JiraIssue -Issue TEST-01 -Assignee 'alice' -UseDefaultAssignee  # error
Set-JiraIssue -Issue TEST-01 -Unassign -UseDefaultAssignee          # error
```

### Empty or null assignee strings

`-Assignee ""` and `-Assignee $null` are now rejected at parameter binding time.
Use `-Unassign` to remove the assignee, or `-UseDefaultAssignee` to fall back to the project default.

### `-Assignee` is no longer positional

`-Assignee` used to be available positionally (after `-Issue`, `-Summary`, `-Description`, and `-FixVersion`).
Because it now belongs to a parameter set and the new `-Unassign` / `-UseDefaultAssignee` switches are all named, `-Assignee` must also be supplied by name in v3.
Scripts that used named arguments are unaffected.

#### v2

```powershell
Set-JiraIssue TEST-01 'new summary' 'new description' @() 'alice'
```

#### v3

```powershell
Set-JiraIssue TEST-01 -Summary 'new summary' -Description 'new description' -Assignee 'alice'
```

### Reporter resolution and validation with `New-JiraIssue`

In v2, `New-JiraIssue -Reporter` accepted `$null`, `''`, and whitespace-only strings, silently forwarded them to Jira's create endpoint, and let the server reject the request with an opaque error.
On Jira Server / Data Center it also bypassed `Resolve-JiraUser` entirely — so a typo'd username only surfaced once Jira returned an error.

In v3:

- `-Reporter` rejects `$null`, `''`, and whitespace-only strings at parameter binding time with an actionable message.
  **Omit `-Reporter` entirely** to let Jira apply the project's default reporter — this matches the API's behaviour and is the supported way to "reset" the reporter on creation.
- `-Reporter` is now resolved through `Resolve-JiraUser` on Server / DC as well, so typos are caught client-side and Cloud / DC use the same code path.
  `Resolve-JiraUser` resolves the deployment-specific identity without searching.

#### v2

```powershell
New-JiraIssue -Project TEST -IssueType Task -Summary 'x' -Reporter ''
New-JiraIssue -Project TEST -IssueType Task -Summary 'x' -Reporter $null
```

#### v3

```powershell
# Use the project's default reporter
New-JiraIssue -Project TEST -IssueType Task -Summary 'x'

# Or set an explicit reporter (resolved exactly via Resolve-JiraUser)
New-JiraIssue -Project TEST -IssueType Task -Summary 'x' -Reporter 'powershell'
```

### Renaming `Format-Jira` → `ConvertTo-JiraTable`

The `Format-Jira` cmdlet has been renamed to `ConvertTo-JiraTable`.
The command returns a string containing Jira wiki-markup table syntax.
It does not produce a formatting object like `Format-Table`.
Treating it as a `ConvertTo-*` is also more honest about the destructive nature of the conversion.

The deprecated `Format-Jira` alias is removed in v3.
Update scripts to use `ConvertTo-JiraTable`.

#### v2

```powershell
Get-Process | Format-Jira | Add-JiraIssueComment -Issue TEST-001
$comment = Get-Process powershell | Format-Jira
```

#### v3

```powershell
Get-Process | ConvertTo-JiraTable | Add-JiraIssueComment -Issue TEST-001
$comment = Get-Process powershell | ConvertTo-JiraTable
```

`ConvertTo-JiraTable` produces Jira wiki markup, the native format for Jira Server / Data Center.
On **Jira Cloud** REST v3 endpoints expect Atlassian Document Format (ADF) and render the resulting `||header||` / `|cell|` syntax as literal text rather than as a table.
See the **Atlassian Document Format (ADF) on Jira Cloud** section below for the recommended Cloud workflow (use Markdown table syntax instead).

### Atlassian Document Format (ADF) on Jira Cloud

Jira Cloud's REST v3 endpoints return rich-text fields (descriptions, comments, worklog comments, environment, multi-line custom text-areas) as Atlassian Document Format (ADF) — a nested JSON document tree — and only accept ADF for those same fields on write.
Jira Server / Data Center continues to use plain wiki-markup strings on both read and write.

Across the cumulative v2 → v3 transition, JiraPS now bridges this difference transparently:

- On **read**, ADF responses are converted to Markdown strings before they reach your script.
- On **write**, plain strings (or Markdown) are wrapped in ADF and dispatched to Cloud's v3 endpoints; on Server / Data Center the value is sent verbatim against v2.

The two subsections below cover the script-visible consequences.

#### Reading rich-text fields

In v2 (before 2.16) `$issue.Description` on Jira Cloud surfaced the raw ADF JSON tree as a deeply nested PSObject.
In v3 it is a Markdown string.
The same change applies to comment bodies (`$issue.Comment[].Body`, `(Get-JiraIssueComment).Body`) and worklog comments (`(Get-JiraIssueWorklog).Comment`).

##### v2

```powershell
$issue = Get-JiraIssue -Key 'TEST-1'
# $issue.Description was an ADF document object — the script had to walk the tree:
$issue.Description.content[0].content[0].text
```

##### v3

```powershell
$issue = Get-JiraIssue -Key 'TEST-1'
# $issue.Description is now a Markdown string:
$issue.Description
```

If your script needs to inspect raw ADF — for example when fetching from an endpoint JiraPS does not wrap, or when round-tripping a payload — call `ConvertFrom-AtlassianDocumentFormat` directly on the JSON.

#### Writing rich-text fields

In v2, plain strings supplied to `-Description`, `-Comment`, `-AddComment`, etc. were sent verbatim against Cloud's v2 endpoint.
Once Cloud completed its ADF migration, that endpoint started rejecting plain strings with `"Operation value must be an Atlassian Document"`, so any v2 script that wrote rich-text content to Cloud would fail.
In v3 the same plain-string call works on both deployment types — JiraPS routes the request to v3 and wraps the body in ADF on Cloud, and to v2 verbatim on Server / Data Center.

##### v2 (silently broken on Cloud)

```powershell
Add-JiraIssueComment -Issue TEST-1 -Comment 'Hello, **world**.'
New-JiraIssue -Project TEST -IssueType Task -Summary 'x' -Description 'See above.'
Set-JiraIssue -Issue TEST-1 -AddComment 'Reviewed.'
Invoke-JiraIssueTransition -Issue TEST-1 -Transition 11 -Comment 'In review.'
Add-JiraIssueWorklog -Issue TEST-1 -TimeSpent '1h' -Comment 'Looked into it.'
```

##### v3 (works on Cloud and Data Center)

```powershell
Add-JiraIssueComment -Issue TEST-1 -Comment 'Hello, **world**.'
New-JiraIssue -Project TEST -IssueType Task -Summary 'x' -Description 'See above.'
Set-JiraIssue -Issue TEST-1 -AddComment 'Reviewed.'
Invoke-JiraIssueTransition -Issue TEST-1 -Transition 11 -Comment 'In review.'
Add-JiraIssueWorklog -Issue TEST-1 -TimeSpent '1h' -Comment 'Looked into it.'
```

The string is interpreted as Markdown on Cloud — headings, bold/italic, lists, fenced code blocks, links, and Markdown tables render as rich text in the issue.
On Server / Data Center the string is sent unchanged and continues to honour the legacy wiki-markup syntax.

For full control over the ADF document (embedded media, mentions, status lozenges, custom panels), supply a pre-built ADF hashtable through the `-Fields` parameter — see the `-Fields` parameter help on `New-JiraIssue`, `Set-JiraIssue`, and `Invoke-JiraIssueTransition`.

##### `ConvertTo-JiraTable` and Cloud

Wiki-markup tables (`||header||`) emitted by `ConvertTo-JiraTable` render as literal text on Cloud — JiraPS warns when it sees that pattern in a Cloud write payload.
Use Markdown table syntax instead; `ConvertTo-AtlassianDocumentFormat` translates it to a real ADF table.
See the **Renaming `Format-Jira` → `ConvertTo-JiraTable`** section above.

### Issue `Status` is now a typed object

Previously, `JiraPS.Issue.Status` was the bare status name string (e.g. `'Open'`).
This made `$issue.Status.Name` evaluate to `$null` and prevented downstream code from inspecting the status category, icon, or REST URL — every other domain field on `JiraPS.Issue` was already strongly typed (`Project`, `Reporter`, `Assignee`, …) so this was a long-standing inconsistency.

`Status` is now an `AtlassianPS.JiraPS.Status` object with `Id`, `Name`, `Description`, `IconUrl`, and `RestUrl` properties.
Its `ToString()` override renders the status name, so string interpolation (`"$($issue.Status)"`), `Write-Output $issue.Status`, and the default formatter continue to print the previous text and most scripts need no change.

The breaking case is direct equality / pattern-match against the bare name:

#### v2

```powershell
if ($issue.Status -eq 'Open') { ... }
$issue.Status -match '^In '
$issue.Status.Substring(0, 3)
```

#### v3

```powershell
if ($issue.Status.Name -eq 'Open') { ... }
$issue.Status.Name -match '^In '
$issue.Status.Name.Substring(0, 3)
```

### Endpoint paths in `Invoke-JiraMethod`

Only Uri supports positional binding.
GetParameter was renamed to QueryParameter.
Query values are supplied unencoded, and arrays become repeated query keys.
Use explicit comma-separated strings where Jira expects comma-separated values.

Structured Body values are serialized as JSON automatically.
JSON strings are sent without additional serialization, strings use UTF-8, and byte arrays are sent unchanged.
ContentType selects the request media type; RawBody was removed.

```powershell
# v2
Invoke-JiraMethod -Uri '/rest/api/2/issue/TEST-1' -GetParameter @{ fields = 'summary,status' }

# v3
Invoke-JiraMethod '/rest/api/2/issue/TEST-1' -QueryParameter @{ fields = 'summary,status' }
Invoke-JiraMethod '/rest/api/2/group' -Method Post -Body @{ name = 'release-reviewers' } -Connection $connection
```

Select a connection through Connection, ConnectionName or the default.
Standalone authentication requires BaseUri with Credential, EmailAddress and ApiToken, PersonalAccessToken, or Anonymous.
Authentication overrides on selected connections are no longer supported.

Paging must be explicit, and First, Skip, IncludeTotalCount and PageSize require Paging.
Automatic paging supports GET offset responses and enhanced-search GET tokens; manage body-based continuation explicitly.
Skip is applied locally for token responses.
RawResponse returns status, headers and content; OutFile saves bytes and returns FileInfo.
Paging, RawResponse and OutFile are mutually exclusive response modes.

StoreSession, InFile, OutputType and the public cache controls were removed.
Use Connect-Jira for reusable connections and Add-JiraIssueAttachment for multipart uploads.
Potential mutations and file output support WhatIf and Confirm.
Automatic retries are limited to GET, HEAD and OPTIONS.

In v3, JiraPS standardizes internal REST calls on relative endpoint paths that match Atlassian documentation (for example, `/rest/api/2/project`).
`Invoke-JiraMethod` resolves those relative paths against the selected connection's API endpoint.
Relative paths must start with `/`.
Calls like `Invoke-JiraMethod -Uri 'rest/api/2/project'` now throw a clear argument error.
Absolute URLs must belong to that connection's endpoint.
Cloud site REST URLs from properties like `RestURL` are mapped to the same connection's API gateway.

#### Recommended in v3

```powershell
Invoke-JiraMethod -Uri '/rest/api/2/project'
Invoke-JiraMethod -Uri '/rest/api/2/issue/TEST-1'
```

### PSTypeName changes in `AtlassianPS.JiraPS.*`

Common JiraPS domain types are now real .NET classes under the `AtlassianPS.JiraPS` namespace, mirroring the long-standing convention used by `ConfluencePS` and other AtlassianPS modules.
Returned objects have `GetType().FullName -eq 'AtlassianPS.JiraPS.<Type>'`, support hashtable construction (`[AtlassianPS.JiraPS.User]@{ Name = 'jdoe' }`), expose strongly-typed cross-references (e.g. `Project.Lead` is `[User]`, `Issue.Project` is `[Project]`), and surface real properties to `Get-Member` and IDE IntelliSense.

The following types were renamed:

| v2 PSTypeName       | v3 .NET full name                |
| ------------------- | -------------------------------- |
| `JiraPS.Issue`      | `AtlassianPS.JiraPS.Issue`       |
| `JiraPS.User`       | `AtlassianPS.JiraPS.User`        |
| `JiraPS.Project`    | `AtlassianPS.JiraPS.Project`     |
| `JiraPS.Filter`     | `AtlassianPS.JiraPS.Filter`      |
| `JiraPS.Version`    | `AtlassianPS.JiraPS.Version`     |
| `JiraPS.Comment`    | `AtlassianPS.JiraPS.Comment`     |
| `JiraPS.Session`    | `AtlassianPS.Connection`        |
| `JiraPS.ServerInfo` | `AtlassianPS.JiraPS.ServerInfo`  |

There is no backward-compatibility alias.
Scripts that inspect `PSObject.TypeNames` or hand-construct mock objects with the legacy `JiraPS.<Type>` name must be updated.

Leaf return types such as `Status`, `Priority`, `IssueType`, `Component`, `Attachment`, `Worklogitem`, `Transition`, `IssueLink`, `ProjectRole`, `FilterPermission`, and metadata field objects are also promoted to `AtlassianPS.JiraPS.*` classes in this release.
New code should prefer `$obj -is [AtlassianPS.JiraPS.<Type>]` checks over inspecting `PSObject.TypeNames`.

#### Type-name inspection

```powershell
# v2
if ('JiraPS.Issue' -in $obj.PSObject.TypeNames) { ... }
$obj.PSObject.TypeNames[0] -eq 'JiraPS.Issue'

# v3
if ($obj -is [AtlassianPS.JiraPS.Issue]) { ... }                # idiomatic
if ('AtlassianPS.JiraPS.Issue' -in $obj.PSObject.TypeNames) { ... }   # also works
$obj.GetType().FullName -eq 'AtlassianPS.JiraPS.Issue'
```

#### Building mock objects in tests

```powershell
# v2 — PSCustomObject with a PSTypeName tag
$mockIssue = [PSCustomObject]@{
    PSTypeName = 'JiraPS.Issue'
    Key        = 'TEST-1'
    Summary    = 'mock issue'
}

# v3 — real strong-typed instance
$mockIssue = [AtlassianPS.JiraPS.Issue]@{
    Key     = 'TEST-1'
    Summary = 'mock issue'
}
```

Prefer typed mock objects.
PowerShell rejects unknown properties when it constructs the object at runtime.
Some command parameters also accept `PSCustomObject` mocks through their argument transformers.
Give those mocks the corresponding `AtlassianPS.JiraPS.<Type>` type name only when the consuming transformer supports it.
The parameters use CLR types and transformation attributes rather than `PSTypeName` attributes.

### Identifier-based equality on strong types

`Issue`, `User`, `Project`, `Group`, `Filter`, and `Version` now implement identifier-based equality and comparison.
This means `-eq`, `-contains`, `Sort-Object -Unique`, `Group-Object`, and hashtable-key lookups now dedupe instances by their canonical identifier instead of by object reference.

Canonical identifier rules:

- `Issue`: `Key`
- `User`: `AccountId` when present, otherwise `Name`
- `Project`: `Key`
- `Group`: `Name`
- `Filter`: `Id`
- `Version`: `Id` when present, otherwise `Name`

#### Cloud and Data Center identity for `User`

Because `User` now prefers `AccountId` over `Name`, scripts that cache or dedupe users across mixed DC/Cloud data can see different grouping behavior after migration.
For stable cross-platform behavior, key persisted caches on `AccountId` when it is available.

### Property type changes in `Filter`, `Version`

The boolean and numeric properties on `AtlassianPS.JiraPS.Filter` and `AtlassianPS.JiraPS.Version` are now strongly typed:

| Property              | v2 slot type | v3 slot type |
| --------------------- | ------------ | ------------ |
| `Filter.Favourite`    | `[object]`   | `[bool]`     |
| `Version.Archived`    | `[object]`   | `[bool]`     |
| `Version.Released`    | `[object]`   | `[bool]`     |
| `Version.Overdue`     | `[object]`   | `[bool]`     |
| `Version.Project`     | `[object]`   | `[long?]`    |

This matches what the Jira REST APIs actually return and lets `Get-Member`, IDE IntelliSense, and `[ValidateScript]` see the real types.

The user-visible behaviour change is around **missing fields**.
The Jira docs describe a missing boolean flag as "not set" (i.e. `false`), and v3 surfaces it that way:

```powershell
# v2 — a Filter without a `favourite` key in the payload
$filter.Favourite -eq $null    # True (slot was [object], default $null)

# v3 — same payload
$filter.Favourite -eq $null    # False
$filter.Favourite -eq $false   # True
```

If your scripts deliberately distinguish "field absent" from "field set to false" via `if ($null -eq $f.Favourite)` you need to switch to a different signal (e.g. inspect the raw payload before the converter runs, or use `[Nullable[bool]]` in your own wrapper code).

### `Version.StartDate` / `Version.ReleaseDate` — empty-string sentinel removed

In v2 the converter emitted an empty string `''` for missing version dates, so user code could keep using `if ($v.StartDate)` short-circuit checks without first thinking about `$null`.
The slots were typed `[object]` to preserve that behaviour.

In v3 the slots are `[DateTime?]` and missing values are `$null`:

```powershell
# v2 — payload without startDate / releaseDate
$v.StartDate -eq ''        # True
$v.StartDate -eq $null     # False

# v3 — same payload
$v.StartDate -eq ''        # False
$v.StartDate -eq $null     # True
```

Truthy short-circuiting still works the same way:

```powershell
if (-not $v.StartDate)     { 'no start date set' }   # works on both v2 and v3
if ($v.StartDate)          { $v.StartDate.AddDays(7) } # works on both v2 and v3
```

Equality comparisons against `''` are the only thing that needs updating.

### Strongly-typed object parameters

JiraPS v3 replaces the old `[Object]` + `ValidateScript` parameter pattern with typed class parameters and transformation attributes.
Commands accept existing typed objects and the identifier or name shorthand documented in their help.
PowerShell converts supported shorthand when binding parameters.
Most scripts can keep passing strings, while newer scripts can pass real `AtlassianPS.JiraPS.*` instances directly.

#### Cmdlet family summary

| Family | Representative parameters | v3 class | Canonical identifier slot |
| ------ | ------------------------- | -------- | ------------------------- |
| Issue | `-Issue` | `[AtlassianPS.JiraPS.Issue]` | `Key` |
| Version | `-Version`, `-After`, `-InputObject` | `[AtlassianPS.JiraPS.Version]` | `Id` (fallback `Name`) |
| Filter | `-Filter` | `[AtlassianPS.JiraPS.Filter]` | `Id` |
| Project | `-Project` | `[AtlassianPS.JiraPS.Project]` | `Key` (or `Id`) |
| User | `-User`, `-Owner`, `-Assignee`, `-Reporter` | `[AtlassianPS.JiraPS.User]` | `AccountId` on Cloud, otherwise `Name` |
| Group | `-Group` | `[AtlassianPS.JiraPS.Group]` | `Name` |

Anything else throws an `ArgumentTransformationMetadataException` at parameter binding time with an actionable message, instead of failing later inside the cmdlet body with a generic `Cannot convert ...` error.

#### Affected cmdlets

`Add-JiraIssueAttachment`, `Add-JiraIssueComment`, `Add-JiraIssueWatcher`, `Add-JiraIssueWorklog`, `Get-JiraIssue`, `Get-JiraIssueAttachment`, `Get-JiraIssueComment`, `Get-JiraIssueWatcher`, `Get-JiraIssueWorklog`, `Get-JiraRemoteLink`, `Invoke-JiraIssueTransition`, `Remove-JiraIssue`, `Remove-JiraIssueAttachment`, `Remove-JiraIssueWatcher`, `Remove-JiraRemoteLink`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

#### `Add-JiraIssueLink` now uses explicit relationship endpoints

`Add-JiraIssueLink` no longer accepts the historical single-issue anchor parameter `-Issue`.
Each create request must now include both relationship endpoints (`inwardIssue` and `outwardIssue`) together with the link `type`.

##### v2

```powershell
$issueLink = [PSCustomObject]@{
    type         = @{ name = "Blocks" }
    outwardIssue = @{ key = "TEST-10" }
}
Add-JiraIssueLink -Issue TEST-01 -IssueLink $issueLink
```

##### v3

```powershell
$issueLink = [PSCustomObject]@{
    type         = @{ name = "Blocks" }
    inwardIssue  = @{ key = "TEST-01" }
    outwardIssue = @{ key = "TEST-10" }
}
Add-JiraIssueLink -IssueLink $issueLink
```

For a simpler authoring experience, use `New-JiraIssueLinkRequest`:

```powershell
$issueLink = New-JiraIssueLinkRequest -Type "Blocks" -FromIssue "TEST-01" -ToIssue "TEST-10"
Add-JiraIssueLink -IssueLink $issueLink
```

#### Passing multiple issues

Pipe multiple issues to a command to process them one at a time.
Parameters declared as a single `Issue` do not accept an array directly.
Commands with `Issue[]` parameters, such as `Remove-JiraIssueLink -Issue`, also accept arrays.

#### One example per family

##### v2

```powershell
# Issue
Add-JiraIssueComment -Issue 'TEST-1' -Comment 'reviewed'

# Version
Set-JiraVersion -Version 10200 -Released

# Filter
Get-JiraIssue -Filter 12345

# Project
Get-JiraComponent -Project 'TEST'

# User
Set-JiraIssue -Issue 'TEST-1' -Assignee 'alice'

# Group
Get-JiraGroupMember -Group 'jira-users'
```

#### Shared behavior changes

- Binding failures now happen in one place with consistent messages (for example, empty or whitespace-only strings now fail during transformation).
- Cmdlet bodies no longer need per-parameter adapter loops to coerce strings, IDs, and legacy objects.
- Pipelines now behave more naturally in the affected cmdlets because typed inputs are transformed before `process` executes.
- `Get-JiraVersion` keeps parameter-set fallthrough behavior when pipeline input belongs to a competing parameter set (for example, project pipelines).

#### Practical migration checks by family

- Issue: Pipe multiple issues to commands with a singular `Issue` parameter.
  Use an array only when the parameter accepts `Issue[]`.
- Version: Stop comparing or passing missing date values as `''`, and use `$null` checks for `StartDate` and `ReleaseDate` instead.
- Filter: Keep treating identifiers as filter IDs, and update any tests that asserted legacy `ValidateScript` wording to assert transformer errors instead.
- Project: Prefer passing project keys or typed `Project` objects directly, and remove helper code that re-queries `Get-JiraProject` only to recover an ID before the real call.
- User: For Cloud and mixed Cloud/DC scripts, use `AccountId` as the stable identity key when persisting or deduplicating users.
- Group: Update mocks and type checks from `JiraPS.Group` to `AtlassianPS.JiraPS.Group`.

#### Hashtable cast still works

The v2-style hashtable cast remains supported for all six identifier-driven classes because each class still exposes a parameterless constructor.
That keeps mock/test setup and explicit property construction viable in v3:

```powershell
[AtlassianPS.JiraPS.Issue]@{ Key = 'TEST-1' }
[AtlassianPS.JiraPS.Version]@{ ID = 10200 }
[AtlassianPS.JiraPS.Filter]@{ ID = 12345 }
[AtlassianPS.JiraPS.Project]@{ Key = 'TEST' }
[AtlassianPS.JiraPS.User]@{ Name = 'alice' }
[AtlassianPS.JiraPS.Group]@{ Name = 'jira-users' }
```

### Convenience constructors on the `AtlassianPS.JiraPS.*` classes

For the common "single identifier" case, v3 also adds string constructors to the same six classes.
They map directly to the same identifier slots used by the transformers:

| Constructor | Stores into |
| ----------- | ----------- |
| `[AtlassianPS.JiraPS.Issue]::new(string)` | `Key` |
| `[AtlassianPS.JiraPS.Version]::new(string)` | `Id` when numeric, otherwise `Name` |
| `[AtlassianPS.JiraPS.Filter]::new(string)` | `Id` |
| `[AtlassianPS.JiraPS.Project]::new(string)` | `Key` |
| `[AtlassianPS.JiraPS.User]::new(string)` | `Name` |
| `[AtlassianPS.JiraPS.Group]::new(string)` | `Name` |

Use the constructor when you only need one identifier, and use hashtable casts when you need to set multiple properties up front.
For broader v3 usage guidance around these classes, see [about_JiraPS_Classes](classes.html).

### Minimum PowerShell version

JiraPS v3 requires PowerShell 5.1 or later.
Windows PowerShell 3.0 and 4.0 are no longer supported.
PowerShell 7+ continues to be fully supported.

### Changes to returned objects and command input

Issue history and its items, remote-link details, visibility, role actors, filter subscriptions and field schemas now return typed .NET objects.
An unassigned issue has `$null` in its `Assignee` property.
Test it with `$null -eq $issue.Assignee` instead of comparing against `Unassigned`.
Known nested issue fields, including versions, components and worklogs, are declared typed properties.
Present empty collections remain empty arrays; missing optional values remain `$null`.

```powershell
$issue = Get-JiraIssue -Key 'TEST-1'
if ($null -eq $issue.Assignee) {
    'This issue is unassigned.'
}
Invoke-JiraIssueTransition -Issue $issue -Transition 'Start Progress'
Add-JiraIssueComment -Issue $issue -Comment 'Team note' -Visibility @{ Type = 'group'; Value = 'jira-users' }
```

`VisibleRole` remains an alias for `Visibility`; role strings and `All Users` remain accepted shorthand.
Commands that accept filters and related Jira objects now declare their .NET types as parameter types.
Check the command help for accepted objects, identifiers and names.
Use a transition name that is available on the issue.
`Remove-JiraFilterPermission` accepts a typed `Filter` or its ID, with `FilterId` and `Id` aliases, and requires explicit `Permission` or `All`.
`PermissionId` remains an alias for `Permission`.
Properties such as user `AccountType`, filter permission `Type` and server `DeploymentType` now use nullable enums.
Unknown API values become `$null`.
When exporting these properties as JSON, cast them to `[string]` to retain their names; `ConvertTo-Json` otherwise writes enum numbers.
Project `Roles` and user `AvatarUrl` now use dictionaries of URI values.
Read entries by key, for example `$project.Roles['Developers']` or `$user.AvatarUrl['16x16']`.
Custom fields, entity-property values, allowed field values and raw REST responses retain the values supplied by Jira.
See [about_JiraPS_Classes](classes.html) for object construction, command input and nested property examples.

## Finding deprecated usage in your scripts

The following commands recursively search your scripts for v2-style usage that needs updating:

```powershell
# Find magic-string assignee usage
Get-ChildItem -Recurse -Filter *.ps1 |
    Select-String -Pattern "-Assignee\s+['""](Unassigned|Default)['""]"

# Find $null or empty assignee/reporter usage
Get-ChildItem -Recurse -Filter *.ps1 |
    Select-String -Pattern "-(Assignee|Reporter)\s+(\`$null|''|""""|'\s+'|""\s+"")"

# Find legacy paging parameters
Get-ChildItem -Recurse -Filter *.ps1 |
    Select-String -Pattern "-(StartIndex|MaxResults)\b"

# Find usages of the deprecated Format-Jira alias
Get-ChildItem -Recurse -Filter *.ps1 |
    Select-String -Pattern "\bFormat-Jira\b"

# Find legacy PSTypeName usage for the eight renamed types
Get-ChildItem -Recurse -Filter *.ps1 |
    Select-String -Pattern "JiraPS\.(Issue|User|Project|Filter|Version|Session|ServerInfo|Comment)\b" |
    Where-Object { $_.Line -notmatch 'AtlassianPS\.JiraPS\.' }
```

# SEE ALSO

- [Set-JiraIssue](../commands/Set-JiraIssue/)
- [Invoke-JiraIssueTransition](../commands/Invoke-JiraIssueTransition/)
- [New-JiraIssue](../commands/New-JiraIssue/)
- [Get-JiraIssue](../commands/Get-JiraIssue/)
- [Get-JiraGroupMember](../commands/Get-JiraGroupMember/)
- [about_JiraPS_Classes](classes.html)
- [CHANGELOG](https://github.com/AtlassianPS/JiraPS/blob/master/CHANGELOG.md)

# KEYWORDS

- Migration
- Breaking Changes
- v3
- Upgrade
