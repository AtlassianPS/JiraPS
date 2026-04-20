---
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/about/migration-v3.html
locale: en-US
layout: documentation
permalink: /docs/JiraPS/about/migration-v3.html
hide: true
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
| Minimum PowerShell version   | Raised from 3.0 to 5.1.                                                 |

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

The string value `'Unassigned'` is no longer recognised by `-Assignee`.
The previously informal convention of passing `$null` is also no longer accepted.
Use the new `-Unassign` switch instead.

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

Previously `Set-JiraIssue -Assignee ""` or `Set-JiraIssue -Assignee $null`
would silently produce different (and often unintended) effects.
In v3 both are rejected with a clear error message pointing you to `-Unassign` or `-UseDefaultAssignee`.

### Minimum PowerShell Version

JiraPS v3 requires PowerShell 5.1 or later.
Windows PowerShell 3.0 and 4.0 are no longer supported. PowerShell 7+ continues to be fully supported.

## FINDING DEPRECATED USAGE IN YOUR SCRIPTS

The following regular expressions can help locate v2-style usage that needs updating:

```powershell
# Find magic-string assignee usage
Select-String -Path *.ps1 -Pattern "-Assignee\s+['""](Unassigned|Default)['""]"

# Find $null assignee usage
Select-String -Path *.ps1 -Pattern "-Assignee\s+\`$null"

# Find legacy paging parameters
Select-String -Path *.ps1 -Pattern "-(StartIndex|MaxResults)\b"
```

# SEE ALSO

- [Set-JiraIssue](../commands/Set-JiraIssue/)
- [Invoke-JiraIssueTransition](../commands/Invoke-JiraIssueTransition/)
- [Get-JiraIssue](../commands/Get-JiraIssue/)
- [Get-JiraGroupMember](../commands/Get-JiraGroupMember/)
- [CHANGELOG](https://github.com/AtlassianPS/JiraPS/blob/master/CHANGELOG.md)

# KEYWORDS

- Migration
- Breaking Changes
- v3
- Upgrade
