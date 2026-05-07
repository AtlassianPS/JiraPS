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

JiraPS v3 removes a number of long-deprecated parameters and "magic string"
values that have been in the codebase for several major versions.
The minimum supported PowerShell version was also raised to 5.1,
allowing the module to adopt newer language features and improve performance.

This guide lists every breaking change introduced in v3 and shows how to update your scripts.

## SUMMARY OF BREAKING CHANGES

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
| `JiraPS.Issue.Status`        | Now a `JiraPS.Status` object instead of the bare status name string.    |
| PSTypeName rename            | Eight core types moved from `JiraPS.<Type>` to `AtlassianPS.JiraPS.<Type>`. |
| Class slot type tightening   | Boolean / numeric slots on `Filter` and `Version` are now strongly typed; missing flags surface as `$false` instead of `$null`. |
| `Version.StartDate` / `Version.ReleaseDate` | Empty-string sentinel for missing dates dropped; the slots are now `[DateTime?]` and `$null` when absent. |
| Issue-scoped cmdlets         | `-Issue` (and `-InputObject` on `Get-JiraIssue` / `Remove-JiraIssue`) is now `[AtlassianPS.JiraPS.Issue]` with a custom transformer; arrays / pipelines iterate the `process` block per item instead of throwing. |
| User-scoped cmdlets          | `-User` / `-UserName` / `-Owner` on `Set-JiraUser`, `Remove-JiraUser`, `Add-JiraGroupMember`, `Remove-JiraGroupMember`, and `Find-JiraFilter` are now strongly-typed `[AtlassianPS.JiraPS.User]` / `[AtlassianPS.JiraPS.User[]]` with a custom transformer. |
| Group promoted to .NET class | `Group` joins the eight original `AtlassianPS.JiraPS.*` types. `ConvertTo-JiraGroup` returns `[AtlassianPS.JiraPS.Group]`; `PSObject.TypeNames[0]` is `AtlassianPS.JiraPS.Group` (was `JiraPS.Group`). |
| Group-scoped cmdlets         | `-Group` on `Add-JiraGroupMember`, `Get-JiraGroupMember`, `Remove-JiraGroup`, and `Remove-JiraGroupMember` is now strongly-typed `[AtlassianPS.JiraPS.Group[]]` with a custom transformer. |
| Version-scoped cmdlets       | `-Version` / `-After` / `-InputObject` / `-InputVersion` on `Get-JiraVersion`, `Move-JiraVersion`, `New-JiraVersion`, `Remove-JiraVersion`, and `Set-JiraVersion` are now strongly-typed `[AtlassianPS.JiraPS.Version]` / `[AtlassianPS.JiraPS.Version[]]` with a custom transformer. |
| Filter-scoped cmdlets        | `-InputObject` on `Get-JiraFilter` and `-Filter` on `Get-JiraIssue` are now strongly-typed `[AtlassianPS.JiraPS.Filter]` / `[AtlassianPS.JiraPS.Filter[]]` with a custom transformer. |
| Project-scoped cmdlets       | `-Project` on `Get-JiraComponent`, `Find-JiraFilter`, `New-JiraVersion`, and `Set-JiraVersion` is now strongly-typed `[AtlassianPS.JiraPS.Project]` / `[AtlassianPS.JiraPS.Project[]]` with a custom transformer. |
| Class construction           | The six identifier-driven `AtlassianPS.JiraPS.*` classes ship a single string-arg constructor for stub-from-an-identifier (`[AtlassianPS.JiraPS.Issue]::new('TEST-1')`). The hashtable-cast form `[AtlassianPS.JiraPS.Issue]@{ Key = 'TEST-1' }` continues to work. |
| Rich-text fields (read)      | On Cloud, returned as Markdown strings instead of ADF JSON trees.       |
| Rich-text fields (write)     | On Cloud, plain strings / Markdown are accepted and wrapped in ADF (previously rejected). |
| Minimum PowerShell version   | Raised from 3.0 to 5.1.                                                 |

## DEPRECATIONS (NON-BREAKING)

The following changes do **not** break existing scripts in v3 — the old name continues to work via an exported alias — but the alias will be removed in a future major version.
Update at your convenience.

| Area          | What Changed                                                                  |
| ------------- | ----------------------------------------------------------------------------- |
| `Format-Jira` | Renamed to `ConvertTo-JiraTable`. The old name is preserved as a deprecated, exported alias. |

## DETAILED MIGRATION GUIDE

### Pagination — `Get-JiraIssue` and `Get-JiraGroupMember`

The legacy parameters `-StartIndex` and `-MaxResults` have been removed in
favor of the standard PowerShell paging parameters `-Skip` and `-First`,
which were already supported in v2.

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

### Unassigning an Issue — `Set-JiraIssue`

Previously, `'Unassigned'` was a magic string and `$null` was the documented way
to unassign. Both are removed in favor of the explicit `-Unassign` switch, which
is more discoverable, symmetric with `-UseDefaultAssignee`, and prevents easy
mistakes such as passing a variable that is unexpectedly `$null`.

#### v2

```powershell
Set-JiraIssue -Issue TEST-01 -Assignee 'Unassigned'
Set-JiraIssue -Issue TEST-01 -Assignee $null
```

#### v3

```powershell
Set-JiraIssue -Issue TEST-01 -Unassign
```

### Default Assignee — `Set-JiraIssue`

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

### Unassigning during a Transition — `Invoke-JiraIssueTransition`

Same change as `Set-JiraIssue`:
the `'Unassigned'` magic string and the `$null` convention have been replaced by the explicit `-Unassign` switch.

#### v2

```powershell
Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Assignee 'Unassigned'
Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Assignee $null
```

#### v3

```powershell
Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Unassign
```

### Mutual Exclusion of Assignee Operations

In v3 the assignee-related parameters live in distinct parameter sets,
so PowerShell will refuse to bind more than one of them in the same call.
This catches mistakes at parse time rather than producing surprising behaviour.

#### Invalid in v3

```powershell
Set-JiraIssue -Issue TEST-01 -Assignee 'alice' -Unassign            # error
Set-JiraIssue -Issue TEST-01 -Assignee 'alice' -UseDefaultAssignee  # error
Set-JiraIssue -Issue TEST-01 -Unassign -UseDefaultAssignee          # error
```

### Empty / Null Assignee Strings

`-Assignee ""` and `-Assignee $null` are now rejected at parameter binding
time. Use `-Unassign` to remove the assignee, or `-UseDefaultAssignee` to
fall back to the project default.

### `-Assignee` is no longer positional

`-Assignee` used to be available positionally (after `-Issue`, `-Summary`,
`-Description`, and `-FixVersion`). Because it now belongs to a parameter
set and the new `-Unassign` / `-UseDefaultAssignee` switches are all named,
`-Assignee` must also be supplied by name in v3. Scripts that used named
arguments are unaffected.

#### v2

```powershell
Set-JiraIssue TEST-01 'new summary' 'new description' @() 'alice'
```

#### v3

```powershell
Set-JiraIssue TEST-01 -Summary 'new summary' -Description 'new description' -Assignee 'alice'
```

### Reporter Resolution and Validation — `New-JiraIssue`

In v2, `New-JiraIssue -Reporter` accepted `$null`, `''`, and whitespace-only
strings, silently forwarded them to Jira's create endpoint, and let the
server reject the request with an opaque error. On Jira Server / Data Center
it also bypassed `Resolve-JiraUser` entirely — so a typo'd username only
surfaced once Jira returned an error.

In v3:

- `-Reporter` rejects `$null`, `''`, and whitespace-only strings at parameter
  binding time with an actionable message. **Omit `-Reporter` entirely** to
  let Jira apply the project's default reporter — this matches the API's
  behaviour and is the supported way to "reset" the reporter on creation.
- `-Reporter` is now resolved through `Resolve-JiraUser` on Server / DC as
  well, so typos are caught client-side and Cloud / DC use the same code
  path. `Resolve-JiraUser` performs an exact match (`-Exact`).

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

### Renaming — `Format-Jira` → `ConvertTo-JiraTable`

The `Format-Jira` cmdlet has been renamed to `ConvertTo-JiraTable`.
The new name reflects what the command actually does: it returns a `[String]` containing Jira wiki-markup table syntax, not a host-only `Format-*` display object like `Format-Table` produces.
Treating it as a `ConvertTo-*` is also more honest about the destructive nature of the conversion.

Existing scripts continue to work because `Format-Jira` is preserved as an exported deprecated alias.
The alias will be removed in a future major version, so update scripts at your convenience.

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
$issue = Get-JiraIssue TEST-1
# $issue.Description was an ADF document object — the script had to walk the tree:
$issue.Description.content[0].content[0].text
```

##### v3

```powershell
$issue = Get-JiraIssue TEST-1
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
See the **Renaming — `Format-Jira` → `ConvertTo-JiraTable`** section above.

### `JiraPS.Issue.Status` is now a `JiraPS.Status` object

Previously, `JiraPS.Issue.Status` was the bare status name string (e.g. `'Open'`).
This made `$issue.Status.Name` evaluate to `$null` and prevented downstream code from inspecting the status category, icon, or REST URL — every other domain field on `JiraPS.Issue` was already strongly typed (`Project`, `Reporter`, `Assignee`, …) so this was a long-standing inconsistency.

`Status` is now a `JiraPS.Status` `PSObject` with `Id`, `Name`, `Description`, `IconUrl`, and `RestUrl` properties.
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

### Endpoint Paths in `Invoke-JiraMethod`

In v3, JiraPS standardizes internal REST calls on relative endpoint paths that match Atlassian documentation (for example, `/rest/api/2/project`).
`Invoke-JiraMethod` resolves those relative paths against `Get-JiraConfigServer`.
Relative paths must start with `/`.
Calls like `Invoke-JiraMethod -Uri 'rest/api/2/project'` now throw a clear argument error.
Absolute URLs are still accepted for backward compatibility and for object properties like `RestURL`.

#### Recommended in v3

```powershell
Invoke-JiraMethod -Uri '/rest/api/2/project'
Invoke-JiraMethod -Uri '/rest/api/2/issue/TEST-1'
```

### PSTypeName Rename — `AtlassianPS.JiraPS.*`

The eight most-used JiraPS domain types are now real .NET classes under the
`AtlassianPS.JiraPS` namespace, mirroring the long-standing convention used by
`ConfluencePS` and other AtlassianPS modules.
Returned objects have `GetType().FullName -eq 'AtlassianPS.JiraPS.<Type>'`,
support hashtable construction (`[AtlassianPS.JiraPS.User]@{ Name = 'jdoe' }`),
expose strongly-typed cross-references (e.g. `Project.Lead` is `[User]`,
`Issue.Project` is `[Project]`), and surface real properties to
`Get-Member` and IDE IntelliSense.

The following types were renamed:

| v2 PSTypeName       | v3 .NET full name                |
| ------------------- | -------------------------------- |
| `JiraPS.Issue`      | `AtlassianPS.JiraPS.Issue`       |
| `JiraPS.User`       | `AtlassianPS.JiraPS.User`        |
| `JiraPS.Project`    | `AtlassianPS.JiraPS.Project`     |
| `JiraPS.Filter`     | `AtlassianPS.JiraPS.Filter`      |
| `JiraPS.Version`    | `AtlassianPS.JiraPS.Version`     |
| `JiraPS.Comment`    | `AtlassianPS.JiraPS.Comment`     |
| `JiraPS.Session`    | `AtlassianPS.JiraPS.Session`     |
| `JiraPS.ServerInfo` | `AtlassianPS.JiraPS.ServerInfo`  |

There is no backward-compatibility alias.
Scripts that inspect `PSObject.TypeNames` or hand-construct mock objects with
the legacy `JiraPS.<Type>` name must be updated.

The remaining 16 leaf types (`Group`, `Status`, `Priority`, `IssueType`,
`IssueLink`, `IssueLinkType`, `Component`, `Attachment`, `Worklogitem`,
`ProjectRole`, `Field`, `CreateMetaField`, `EditMetaField`, `Transition`,
`Link`, `FilterPermission`) keep the legacy `JiraPS.<Type>` PSTypeName
until a follow-up phase converts them too.

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

The v3 form is preferred (it gives parse-time errors for typo'd property
names), but if a test must keep the v2 hashtable shape, just rename the
`PSTypeName` value to `'AtlassianPS.JiraPS.<Type>'` and it will continue
to bind correctly to `[PSTypeName('AtlassianPS.JiraPS.<Type>')]`
parameter attributes.

### Identifier-based equality on strong types

`Issue`, `User`, `Project`, `Group`, `Filter`, and `Version` now implement
identifier-based equality and comparison. This means `-eq`, `-contains`,
`Sort-Object -Unique`, `Group-Object`, and hashtable-key lookups now dedupe
instances by their canonical identifier instead of by object reference.

Canonical identifier rules:

- `Issue`: `Key`
- `User`: `AccountId` when present, otherwise `Name`
- `Project`: `Key`
- `Group`: `Name`
- `Filter`: `ID`
- `Version`: `ID` when present, otherwise `Name`

#### Cloud/Data Center note for `User`

Because `User` now prefers `AccountId` over `Name`, scripts that cache or
dedupe users across mixed DC/Cloud data can see different grouping behavior
after migration. For stable cross-platform behavior, key persisted caches on
`AccountId` when it is available.

### Class slot type tightening — `Filter`, `Version`

The boolean and numeric properties on `AtlassianPS.JiraPS.Filter` and
`AtlassianPS.JiraPS.Version` are now strongly typed:

| Property              | v2 slot type | v3 slot type |
| --------------------- | ------------ | ------------ |
| `Filter.Favourite`    | `[object]`   | `[bool]`     |
| `Version.Archived`    | `[object]`   | `[bool]`     |
| `Version.Released`    | `[object]`   | `[bool]`     |
| `Version.Overdue`     | `[object]`   | `[bool]`     |
| `Version.Project`     | `[object]`   | `[long?]`    |

This matches what the Jira REST APIs actually return and lets `Get-Member`,
IDE IntelliSense, and `[ValidateScript]` see the real types.

The user-visible behaviour change is around **missing fields**.
The Jira docs describe a missing boolean flag as "not set" (i.e. `false`),
and v3 surfaces it that way:

```powershell
# v2 — a Filter without a `favourite` key in the payload
$filter.Favourite -eq $null    # True (slot was [object], default $null)

# v3 — same payload
$filter.Favourite -eq $null    # False
$filter.Favourite -eq $false   # True
```

If your scripts deliberately distinguish "field absent" from "field set to
false" via `if ($null -eq $f.Favourite)` you need to switch to a different
signal (e.g. inspect the raw payload before the converter runs, or use
`[Nullable[bool]]` in your own wrapper code).

### `Version.StartDate` / `Version.ReleaseDate` — empty-string sentinel removed

In v2 the converter emitted an empty string `''` for missing version dates,
so user code could keep using `if ($v.StartDate)` short-circuit checks
without first thinking about `$null`. The slots were typed `[object]` to
preserve that behaviour.

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

### Strongly-typed `-Issue` parameter on issue-scoped cmdlets

In v2, every cmdlet that took a `-Issue` parameter declared it as `[Object]`
with a `[ValidateScript]` block that hand-rolled the "is this a string or a
`JiraPS.Issue` `PSCustomObject`?" check. After binding succeeded, each cmdlet
also asserted `if (@($Issue).Count -ne 1) { throw }` to refuse arrays.

In v3 the parameter is declared `[AtlassianPS.JiraPS.Issue]` and decorated with
the new `[AtlassianPS.JiraPS.IssueTransformation()]` attribute. The transformer
runs at parameter binding time and accepts:

- An existing `[AtlassianPS.JiraPS.Issue]` instance (returned as-is).
- A non-empty issue-key string — wrapped in a stub `Issue` whose `Key` is set;
  the cmdlet's own `Resolve-JiraIssueObject` call then performs the GET as
  before.
- A legacy `PSCustomObject` decorated with the `AtlassianPS.JiraPS.Issue`
  `PSTypeName` — its scalar slots are mapped to a real `Issue` instance so
  hand-rolled v2 mocks keep working without changes.

Anything else throws an `ArgumentTransformationMetadataException` at parameter
binding time with an actionable message, instead of failing later inside the
cmdlet body with a generic `Cannot convert ...` error.

#### Affected cmdlets

`Add-JiraIssueAttachment`, `Add-JiraIssueComment`, `Add-JiraIssueLink`,
`Add-JiraIssueWatcher`, `Add-JiraIssueWorklog`, `Get-JiraIssue`
(`-InputObject`), `Get-JiraIssueAttachment`, `Get-JiraIssueComment`,
`Get-JiraIssueWatcher`, `Get-JiraIssueWorklog`, `Get-JiraRemoteLink`,
`Invoke-JiraIssueTransition`, `Remove-JiraIssue` (`-InputObject`),
`Remove-JiraIssueAttachment`, `Remove-JiraIssueWatcher`,
`Remove-JiraRemoteLink`, `Set-JiraIssue`, `Set-JiraIssueLabel`.

#### Pipelines and arrays now iterate

The "single Issue only" runtime guardrail was removed from cmdlets where
pipeline iteration is the obviously-correct behaviour. The cmdlet's `process`
block now runs once per piped (or array-bound) issue, matching the rest of
PowerShell.

##### v2

```powershell
# Pipeline iteration: throws "Only one issue at a time"
Get-JiraIssue -Query 'project = TEST' | Add-JiraIssueComment -Comment 'reviewed'

# Array bind: same throw
Add-JiraIssueComment -Issue @($issueA, $issueB) -Comment 'reviewed'
```

##### v3

```powershell
# Pipeline iteration: comments each issue once
Get-JiraIssue -Query 'project = TEST' | Add-JiraIssueComment -Comment 'reviewed'

# Array bind: comments each issue once
Add-JiraIssueComment -Issue @($issueA, $issueB) -Comment 'reviewed'
```

If your script previously *relied* on the old guardrail to surface "you passed
too many issues" mistakes, replace it with an explicit check before the call:

```powershell
if (@($Issue).Count -gt 1) {
    throw "This script only supports one issue at a time"
}
Add-JiraIssueComment -Issue $Issue -Comment 'reviewed'
```

#### `Remove-JiraIssueAttachment` pipeline binding

`-Issue` on `Remove-JiraIssueAttachment` no longer accepts `ValueFromPipeline`
(it still accepts `ValueFromPipelineByPropertyName`). This lets the obvious
pipeline shape work for the first time:

```powershell
# v3 — binds the attachment's Id to -AttachmentId via property name
Get-JiraIssueAttachment -Issue TEST-1 | Remove-JiraIssueAttachment
```

In v2 the same call mis-bound the attachment object to `-Issue` and surfaced a
type-conversion error.

### Strongly-typed `-User` parameter on user-scoped cmdlets

The public cmdlets that previously accepted `-User` / `-UserName` / `-Owner` /
`-Assignee` / `-Reporter` as `[Object]` (or `[String]`) with a polymorphic
`[ValidateScript]` block now declare a real typed parameter and use the new
`[AtlassianPS.JiraPS.UserTransformation()]` attribute to coerce the bound value
at parameter binding time:

| Cmdlet                       | Parameter   | v2 declaration                | v3 declaration                |
| ---------------------------- | ----------- | ----------------------------- | ----------------------------- |
| `Add-JiraGroupMember`        | `-UserName` | `[Object[]]` + ValidateScript | `[AtlassianPS.JiraPS.User[]]` |
| `Find-JiraFilter`            | `-Owner`    | `[Object]`  + ValidateScript  | `[AtlassianPS.JiraPS.User]`   |
| `Invoke-JiraIssueTransition` | `-Assignee` | `[Object]`  + ValidateScript  | `[AtlassianPS.JiraPS.User]`   |
| `New-JiraIssue`              | `-Assignee` | `[Object]`  + ValidateScript  | `[AtlassianPS.JiraPS.User]`   |
| `New-JiraIssue`              | `-Reporter` | `[String]`  + ValidateScript  | `[AtlassianPS.JiraPS.User]`   |
| `Remove-JiraGroupMember`     | `-User`     | `[Object[]]` + ValidateScript | `[AtlassianPS.JiraPS.User[]]` |
| `Remove-JiraUser`            | `-User`     | `[Object[]]` + ValidateScript | `[AtlassianPS.JiraPS.User]`   |
| `Set-JiraIssue`              | `-Assignee` | `[Object]`  + ValidateScript  | `[AtlassianPS.JiraPS.User]`   |
| `Set-JiraUser`               | `-User`     | `[Object[]]` + ValidateScript | `[AtlassianPS.JiraPS.User]`   |

The transformer accepts:

- An existing `[AtlassianPS.JiraPS.User]` instance (returned as-is).
- A non-empty identifier string — wrapped in a stub `User` whose `Name` slot
  holds the raw identifier; `Resolve-JiraUser` inspects it at call time and
  dispatches to `/accountId` or `/username` based on the detected platform
  (Cloud vs Data Center).
- A legacy `PSCustomObject` decorated with the `AtlassianPS.JiraPS.User`
  `PSTypeName` — its scalar slots are mapped to a real `User` instance so
  hand-rolled v2 mocks keep working without changes.

Anything else throws an `ArgumentTransformationMetadataException` at parameter
binding time with an actionable message.

#### Pipeline iteration replaces internal fan-out

`Set-JiraUser` and `Remove-JiraUser` previously had an internal
`foreach ($_user in $User) { ... }` loop. With a single typed `[User]`
parameter and `ValueFromPipeline`, PowerShell already iterates the `process`
block once per piped item, so the inner loop is gone:

##### v2 / v3 — both behave identically

```powershell
Get-JiraGroupMember -Group dev | Remove-JiraUser -Force
'alice', 'bob' | Set-JiraUser -DisplayName 'New Name'
```

`Remove-JiraGroupMember` keeps the `-User` array fan-out because each user has
to be paired against every `-Group` in the cross-product:

```powershell
Remove-JiraGroupMember -Group 'dev', 'qa' -User 'alice', 'bob' -Force
```

#### `Find-JiraFilter -Owner` resolution

`Find-JiraFilter -Owner` now resolves the user through `Resolve-JiraUser`
(which handles the Cloud-vs-DC `accountId`/`username` dispatch consistently)
instead of calling `Get-JiraUser -InputObject` directly. The public surface
is unchanged for callers; the only observable difference is that an unknown
owner is now rejected with the standard `Resolve-JiraUser` error message.

#### Whitespace error message on issue-scoped `-Assignee` / `-Reporter`

`Set-JiraIssue -Assignee`, `Invoke-JiraIssueTransition -Assignee`, and
`New-JiraIssue -Assignee`/`-Reporter` previously rejected empty-or-whitespace
strings with cmdlet-specific `ValidateScript` messages such as
*"The -Assignee value cannot be a whitespace-only string. Use -Unassign…"*.
The contract is unchanged — empty/whitespace strings still fail at parameter
binding — but the wording now comes from the shared transformer:

```
Cannot bind an empty or whitespace string to a User parameter.
```

Scripts that asserted on the old wording (e.g.
`Should -Throw -ExpectedMessage '*whitespace-only string*'`) need to be
relaxed to `*empty or whitespace*`.

### Strongly-typed `-Group` parameter on group-scoped cmdlets

`Group` joined the `AtlassianPS.JiraPS.*` namespace as a real .NET class,
exposing `Name [string]`, `RestUrl [string]`, `Size [int]`, and
`Member [AtlassianPS.JiraPS.User[]]`. `ConvertTo-JiraGroup` now returns
`[AtlassianPS.JiraPS.Group]` instances directly, so:

- `GetType().FullName` is `AtlassianPS.JiraPS.Group` (was `System.Management.Automation.PSCustomObject`).
- `PSObject.TypeNames[0]` is `AtlassianPS.JiraPS.Group` (was `JiraPS.Group`).
- The format-data engine still picks up the type because the `.format.ps1xml`
  selector was updated alongside the rename.

The four group-scoped public cmdlets that previously declared `-Group` as
`[Object[]]` with a polymorphic `[ValidateScript]` block now use the new
`[AtlassianPS.JiraPS.GroupTransformation()]` attribute against a real typed
parameter:

| Cmdlet                   | v2 declaration                | v3 declaration                  |
| ------------------------ | ----------------------------- | ------------------------------- |
| `Add-JiraGroupMember`    | `[Object[]]` + ValidateScript | `[AtlassianPS.JiraPS.Group[]]`  |
| `Get-JiraGroupMember`    | `[Object[]]` + ValidateScript | `[AtlassianPS.JiraPS.Group[]]`  |
| `Remove-JiraGroup`       | `[Object[]]` + ValidateScript | `[AtlassianPS.JiraPS.Group[]]`  |
| `Remove-JiraGroupMember` | `[Object[]]` + ValidateScript | `[AtlassianPS.JiraPS.Group[]]`  |

The transformer accepts:

- An existing `[AtlassianPS.JiraPS.Group]` instance (returned as-is).
- A non-empty group-name string — wrapped in a stub `Group` whose `Name` slot
  holds the raw identifier.
- A legacy `PSCustomObject` decorated with the `AtlassianPS.JiraPS.Group`
  `PSTypeName` (or, for backward compatibility with hand-rolled v2 mocks, the
  historical `JiraPS.Group` `PSTypeName`) — its scalar slots are mapped to a
  real `Group` instance.

Anything else throws an `ArgumentTransformationMetadataException` at parameter
binding time. Empty or whitespace-only strings, which previously slipped
through `ValidateScript` and produced opaque server errors, now fail at
binding with:

```
Cannot bind an empty or whitespace string to a Group parameter.
```

#### Updating mocks and TypeName checks

```powershell
# v2
[PSCustomObject]@{ PSTypeName = 'JiraPS.Group'; Name = 'dev' }
if ('JiraPS.Group' -in $g.PSObject.TypeNames) { ... }

# v3
[AtlassianPS.JiraPS.Group]@{ Name = 'dev' }
if ($g -is [AtlassianPS.JiraPS.Group]) { ... }
# (or the equivalent `'AtlassianPS.JiraPS.Group' -in $g.PSObject.TypeNames`)
```

### Strongly-typed `-Version` parameter on version-scoped cmdlets

The five version-scoped public cmdlets that previously declared `-Version` /
`-After` / `-InputObject` / `-InputVersion` as `[Object]` (or `[Object[]]`) with
a polymorphic `[ValidateScript]` block (accepting an `AtlassianPS.JiraPS.Version`
`PSTypeName`, an `[Int]` ID, or a `[String]` Version name) now declare a real
typed parameter and use the new `[AtlassianPS.JiraPS.VersionTransformation()]`
attribute against it:

| Cmdlet              | Parameter      | v2 declaration                  | v3 declaration                    |
| ------------------- | -------------- | ------------------------------- | --------------------------------- |
| `Get-JiraVersion`   | `-InputVersion`| `[Object]`   + ValidateScript   | `[AtlassianPS.JiraPS.Version]`    |
| `Move-JiraVersion`  | `-Version`     | `[Object]`   + ValidateScript   | `[AtlassianPS.JiraPS.Version]`    |
| `Move-JiraVersion`  | `-After`       | `[Object]`   + ValidateScript   | `[AtlassianPS.JiraPS.Version]`    |
| `New-JiraVersion`   | `-InputObject` | `[Object]`   + ValidateScript   | `[AtlassianPS.JiraPS.Version]`    |
| `Remove-JiraVersion`| `-Version`     | `[Object[]]` + ValidateScript   | `[AtlassianPS.JiraPS.Version[]]`  |
| `Set-JiraVersion`   | `-Version`     | `[Object[]]` + ValidateScript   | `[AtlassianPS.JiraPS.Version[]]`  |

The transformer accepts:

- An existing `[AtlassianPS.JiraPS.Version]` instance (returned as-is).
- A numeric scalar (any integer width — Jira version IDs are integral) — wrapped
  in a stub `Version` whose `ID` is set; the cmdlet's body uses the ID directly.
- A non-empty string — parsed as a version ID when it looks numeric, otherwise
  stored in `Name` for the `New-JiraVersion -InputObject 'My Version'` shape
  that fell out of the previous `[Object]` parameter.
- A legacy `PSCustomObject` decorated with the `AtlassianPS.JiraPS.Version`
  `PSTypeName` (or the historical `JiraPS.Version` for hand-rolled v2 mocks) —
  its scalar slots are mapped to a real `Version` instance.

Empty or whitespace-only strings now fail at parameter binding with:

```
Cannot bind an empty or whitespace string to a Version parameter.
```

#### Parameter-set fallthrough on `Get-JiraVersion`

Unlike the Issue / User / Group transformers, `VersionTransformation` returns
the input unchanged (rather than throwing) when the value is not one of the
recognized shapes. `Get-JiraVersion` has sister `ValueFromPipeline` parameter
sets — notably `-InputProject [PSTypeName('AtlassianPS.JiraPS.Project')]` — and
a hard transformer throw would block PowerShell's parameter-set fallthrough.
Returning the value untouched lets the binder reject it cleanly and try the next
set, preserving the well-known `Get-JiraProject ... | Get-JiraVersion` pipeline.

#### Internal adapter blocks removed

The adapter pattern that every Version-mutating cmdlet used to massage `[Object]`
input into an ID is gone:

##### v2

```powershell
foreach ($_version in $Version) {
    if ($_version.Id) { $versionId = $_version.Id }
    else              { $versionId = $_version }
    # …call Invoke-JiraMethod with $versionId…
}
```

##### v3

```powershell
foreach ($_version in $Version) {
    # $_version is always a real [AtlassianPS.JiraPS.Version]
    Invoke-JiraMethod -URI ".../version/$($_version.Id)" …
}
```

Scripts that already passed `Get-JiraVersion … | Set-JiraVersion …`-style
pipelines or real `[AtlassianPS.JiraPS.Version]` objects need no changes.

#### `New-JiraVersion -InputObject` body fixes

The transformer move uncovered two bugs in `New-JiraVersion -InputObject` that
were masked by the `[Object]` parameter:

- The request body now skips `releaseDate` / `startDate` when the slot is
  `$null` instead of calling `.ToString('yyyy-MM-dd')` on a `$null` and emitting
  a malformed payload.
- The project ID is read from the new strongly-typed `Version.Project [long?]`
  slot instead of the legacy `Project.Key`/`Project.Id` PSObject lookup.

### Strongly-typed `-Filter` / `-InputObject` parameter on filter-scoped cmdlets

The two filter-scoped public cmdlets that previously declared `-InputObject` /
`-Filter` as `[Object]`/`[Object[]]` with a polymorphic `[ValidateScript]` block
(accepting an `AtlassianPS.JiraPS.Filter` `PSTypeName` or a `[String]` filter
ID) now declare a real typed parameter and use the new
`[AtlassianPS.JiraPS.FilterTransformation()]` attribute against it:

| Cmdlet            | Parameter      | v2 declaration                  | v3 declaration                    |
| ----------------- | -------------- | ------------------------------- | --------------------------------- |
| `Get-JiraFilter`  | `-InputObject` | `[Object[]]` + ValidateScript   | `[AtlassianPS.JiraPS.Filter[]]`   |
| `Get-JiraIssue`   | `-Filter`      | `[Object]`   + ValidateScript   | `[AtlassianPS.JiraPS.Filter]`     |

The transformer accepts:

- An existing `[AtlassianPS.JiraPS.Filter]` instance (returned as-is).
- A numeric scalar (any integer width — Jira filter IDs are integral) — wrapped
  in a stub `Filter` whose `ID` is set.
- A non-empty string — treated as a filter ID, matching the historic
  `Get-JiraFilter -InputObject [String]` shape that always called `.ToString()`
  on the value and forwarded it to `-Id`.
- A legacy `PSCustomObject` decorated with the `AtlassianPS.JiraPS.Filter`
  `PSTypeName` (or the historical `JiraPS.Filter` for hand-rolled v2 mocks).

Empty or whitespace-only strings now fail at parameter binding with:

```
Cannot bind an empty or whitespace string to a Filter parameter.
```

#### Adapter blocks removed

`Get-JiraFilter`'s body used to massage `[Object]` input into an ID:

##### v2

```powershell
foreach ($object in $InputObject) {
    if ('AtlassianPS.JiraPS.Filter' -in $object.PSObject.TypeNames) {
        $thisId = $object.ID
    }
    else {
        $thisId = $object.ToString()
    }
    Get-JiraFilter -Id $thisId
}
```

##### v3

```powershell
foreach ($object in $InputObject) {
    # $object is always a real [AtlassianPS.JiraPS.Filter]
    Get-JiraFilter -Id $object.ID
}
```

`Get-JiraIssue -Filter` no longer round-trips through `Get-JiraFilter
-InputObject` either; it calls `Get-JiraFilter -Id $Filter.ID` directly,
removing one layer of indirection.

### Strongly-typed `-Project` parameter on project-scoped cmdlets

The four project-scoped public cmdlets that previously declared `-Project` as
`[Object]`/`[Object[]]` with a polymorphic `[ValidateScript]` block (accepting
an `AtlassianPS.JiraPS.Project` `PSTypeName`, an `[Int]` ID, or a `[String]`
key) now declare a real typed parameter and use the new
`[AtlassianPS.JiraPS.ProjectTransformation()]` attribute against it:

| Cmdlet            | Parameter   | v2 declaration                  | v3 declaration                    |
| ----------------- | ----------- | ------------------------------- | --------------------------------- |
| `Get-JiraComponent` | `-Project` | `[Object[]]` + ValidateScript   | `[AtlassianPS.JiraPS.Project[]]`  |
| `Find-JiraFilter`   | `-Project` | `[Object]`   + ValidateScript   | `[AtlassianPS.JiraPS.Project]`    |
| `New-JiraVersion`   | `-Project` | `[Object]`   + ValidateScript   | `[AtlassianPS.JiraPS.Project]`    |
| `Set-JiraVersion`   | `-Project` | `[Object]`   + ValidateScript   | `[AtlassianPS.JiraPS.Project]`    |

The transformer accepts:

- An existing `[AtlassianPS.JiraPS.Project]` instance (returned as-is).
- A numeric scalar (any integer width — Jira project IDs are integral on the
  wire) — wrapped in a stub `Project` whose `ID` is set.
- A non-empty string — treated as a project key, matching the historic call-
  site contract that forwarded the raw value to `Get-JiraProject -Project` or
  to `/project/{idOrKey}` URLs (project keys are uppercase letters; numeric IDs
  go through the integer overload above).
- A legacy `PSCustomObject` decorated with the `AtlassianPS.JiraPS.Project`
  `PSTypeName` (or the historical `JiraPS.Project` for hand-rolled v2 mocks).

Empty or whitespace-only strings now fail at parameter binding with:

```
Cannot bind an empty or whitespace string to a Project parameter.
```

#### Adapter blocks removed

`Find-JiraFilter`, `New-JiraVersion`, and `Set-JiraVersion` used to massage
`[Object]` input into a project ID by re-querying the server:

##### v2

```powershell
if ($Project.Id) {
    $projectId = $Project.Id
}
else {
    $projectObj = Get-JiraProject -Project $Project
    $projectId  = $projectObj.Id
}
$requestBody["projectId"] = $projectId
```

##### v3

```powershell
# $Project is always a real [AtlassianPS.JiraPS.Project]
if ($Project.Id) {
    $requestBody["projectId"] = $Project.Id
}
elseif ($Project.Key) {
    # Cloud v3 / DC v2 create endpoints accept the key under "project"
    $requestBody["project"] = $Project.Key
}
```

`Get-JiraComponent -Project` reads `$_project.Key` (or `$_project.ID` when only
an ID was bound) and inlines it into the `/project/{idOrKey}/components` URL —
no separate `Get-JiraProject` round-trip.

### Convenience constructors on the `AtlassianPS.JiraPS.*` classes

The six identifier-driven classes — `Issue`, `User`, `Project`, `Group`,
`Filter`, and `Version` — each ship a single string-arg constructor that
covers the recurring "build a stub from one identifier" case. The routing
mirrors the matching `*TransformationAttribute` so that a value built via
`::new()` and a value bound via `-Parameter <string>` produce the exact
same stub:

| Constructor                                  | Stores into                                           |
| -------------------------------------------- | ----------------------------------------------------- |
| `[AtlassianPS.JiraPS.Issue]::new(string)`    | `Key`                                                 |
| `[AtlassianPS.JiraPS.User]::new(string)`     | `Name` (Resolve-JiraUser routes by shape at call time)|
| `[AtlassianPS.JiraPS.Project]::new(string)`  | `Key`                                                 |
| `[AtlassianPS.JiraPS.Group]::new(string)`    | `Name`                                                |
| `[AtlassianPS.JiraPS.Filter]::new(string)`   | `ID`                                                  |
| `[AtlassianPS.JiraPS.Version]::new(string)`  | `ID` if the input parses as an integer, else `Name`   |

Null, empty, or whitespace-only input throws `ArgumentException`.

#### v2 — hashtable cast

The hashtable cast still works in v3 (we keep an explicit parameterless
ctor on every class for exactly this reason), but it is verbose for the
common single-identifier case and does not surface in IntelliSense:

```powershell
'TEST-1','TEST-2','TEST-3' |
    ForEach-Object { [AtlassianPS.JiraPS.Issue]@{ Key = $_ } } |
    Add-JiraIssueComment -Comment 'reviewed'
```

#### v3 — convenience ctor

```powershell
'TEST-1','TEST-2','TEST-3' |
    ForEach-Object { [AtlassianPS.JiraPS.Issue]::new($_) } |
    Add-JiraIssueComment -Comment 'reviewed'
```

`Comment`, `Session`, and `ServerInfo` are intentionally not extended with
string-arg ctors — they are never stub-constructed by user scripts in
practice and a string-arg ctor would suggest a contract (e.g., "comment
body string") that does not match the multi-field, server-populated shape
of the type.

### Minimum PowerShell Version

JiraPS v3 requires PowerShell 5.1 or later.
Windows PowerShell 3.0 and 4.0 are no longer supported. PowerShell 7+ continues to be fully supported.

## FINDING DEPRECATED USAGE IN YOUR SCRIPTS

The following commands recursively search your scripts for v2-style usage
that needs updating:

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
- [CHANGELOG](https://github.com/AtlassianPS/JiraPS/blob/master/CHANGELOG.md)

# KEYWORDS

- Migration
- Breaking Changes
- v3
- Upgrade
