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
Wrapping the write-side text payloads (`Add-JiraIssueComment`, `Add-JiraIssueWorklog`, `New-JiraIssue -Description`, etc.) in ADF on Cloud is tracked in [#602](https://github.com/AtlassianPS/JiraPS/issues/602).

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
