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
