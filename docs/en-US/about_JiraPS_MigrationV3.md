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
| PSTypeName rename            | Eight core types moved from `JiraPS.<Type>` to `AtlassianPS.JiraPS.<Type>`. |
| Class slot type tightening   | Boolean / numeric slots on `Filter` and `Version` are now strongly typed; missing flags surface as `$false` instead of `$null`. |
| `Version.StartDate` / `Version.ReleaseDate` | Empty-string sentinel for missing dates dropped; the slots are now `[DateTime?]` and `$null` when absent. |
| Issue-scoped cmdlets         | `-Issue` (and `-InputObject` on `Get-JiraIssue` / `Remove-JiraIssue`) is now `[AtlassianPS.JiraPS.Issue]` with a custom transformer; arrays / pipelines iterate the `process` block per item instead of throwing. |
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
