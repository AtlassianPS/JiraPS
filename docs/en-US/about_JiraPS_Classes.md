---
locale: en-US
layout: documentation
online version: https://atlassianps.org/docs/JiraPS/about/classes.html
Module Name: JiraPS
permalink: /docs/JiraPS/about/classes.html
---
# JiraPS

## about_JiraPS_Classes

# SHORT DESCRIPTION

This topic explains how to use the `AtlassianPS.JiraPS.*` classes introduced and expanded in JiraPS v3.

# LONG DESCRIPTION

JiraPS v3 promotes core domain objects to real .NET classes under the `AtlassianPS.JiraPS` namespace.
Those classes are used for converter output, parameter binding, and transformer-based input coercion across public cmdlets.
For a migration-focused view of what changed from v2, see [about_JiraPS_MigrationV3](migration-v3.html).

## The six identifier-driven classes

These six classes are the common "stub by identifier" entry points in scripts.

| Class | Canonical identifier slot |
| ----- | ------------------------- |
| `AtlassianPS.JiraPS.Issue` | `Key` |
| `AtlassianPS.JiraPS.Version` | `ID` (fallback `Name`) |
| `AtlassianPS.JiraPS.Filter` | `ID` |
| `AtlassianPS.JiraPS.Project` | `Key` (or `ID`) |
| `AtlassianPS.JiraPS.User` | `AccountId` on Cloud, otherwise `Name` |
| `AtlassianPS.JiraPS.Group` | `Name` |

## Three ways to construct a stub

### 1) String constructor

Use `::new('<identifier>')` for concise "single value" creation.

```powershell
$issue = [AtlassianPS.JiraPS.Issue]::new('TEST-1')
Add-JiraIssueComment -Issue $issue -Comment 'Ready for review.'
```

### 2) Hashtable cast

Use a cast when you want to set multiple properties up front.

```powershell
$version = [AtlassianPS.JiraPS.Version]@{
    ID       = 10200
    Released = $true
}
Set-JiraVersion -Version $version
```

### 3) Pipeline from a resolved object

Use converter-returned objects directly when chaining cmdlets.

```powershell
Get-JiraIssue -Query 'project = TEST AND status = "In Review"' |
    Add-JiraIssueComment -Comment 'Review sign-off complete.'
```

## How transformers route input

Most strongly-typed cmdlet parameters in v3 use `*TransformationAttribute` classes.
The routing rules are consistent across families:

- String input creates an identifier stub for the target class.
- Numeric input is treated as an ID where the class supports numeric identity (`Version`, `Filter`, `Project`).
- Existing `AtlassianPS.JiraPS.*` instances pass through unchanged.
- Legacy `PSCustomObject` values with the relevant `PSTypeName` are converted into the corresponding class for backward compatibility.

This lets v2-style scripts keep passing plain strings while v3 scripts can pass richer objects without extra glue code.

## Working with resolved objects

Resolved objects returned by cmdlets are real class instances, so they work naturally with type checks and tab completion.
`ToString()` returns the canonical identifier for user-friendly output in pipelines, logs, and interpolation.
Identifier-based equality and comparisons deduplicate correctly (`-eq`, `Sort-Object -Unique`, hashtable keys) in JiraPS v3.

When you need properties that are not modeled on a given class, query the relevant endpoint/cmdlet that surfaces that data and inspect the returned payload shape before building assumptions into script logic.
In practice, prefer explicit property access for stable fields and avoid relying on display formatting as data.

# SEE ALSO

- [about_JiraPS_MigrationV3](migration-v3.html)
- [Get-JiraIssue](../commands/Get-JiraIssue/)
- [Set-JiraIssue](../commands/Set-JiraIssue/)
