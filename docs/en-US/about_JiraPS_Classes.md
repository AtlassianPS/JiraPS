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

Construct and use JiraPS objects from the `AtlassianPS.JiraPS` namespace.

# LONG DESCRIPTION

JiraPS commands return .NET objects with typed properties for issues, users, projects, filters and related Jira data.
Commands that accept these objects can use them directly, including through the pipeline where the parameter supports it.
Import JiraPS before referring to its types in a script.

```powershell
Import-Module JiraPS

$issue = Get-JiraIssue -Key 'TEST-1'
$issue -is [AtlassianPS.JiraPS.Issue]
$issue.Status.Name
```

## Constructing objects

### Identifier constructors

The following classes have a string constructor that creates an object containing an identifier.
Construction does not fetch data from Jira.

| Class | Property set by the string constructor |
| ----- | -------------------------------------- |
| `AtlassianPS.JiraPS.Issue` | `Key` |
| `AtlassianPS.JiraPS.Version` | `Id` for a numeric string, otherwise `Name` |
| `AtlassianPS.JiraPS.Filter` | `Id` |
| `AtlassianPS.JiraPS.Project` | `Key` |
| `AtlassianPS.JiraPS.User` | `Name` |
| `AtlassianPS.JiraPS.Group` | `Name` |

```powershell
$issue = [AtlassianPS.JiraPS.Issue]::new('TEST-1')
Add-JiraIssueComment -Issue $issue -Comment 'Ready for review.'
```

Use an explicit `AccountId` when constructing a Cloud user, or `Name` for a Data Center user.

```powershell
$cloudUser = [AtlassianPS.JiraPS.User]@{ AccountId = 'account-id' }
$dataCenterUser = [AtlassianPS.JiraPS.User]@{ Name = 'alice' }
```

### Hashtable casts

Cast a hashtable to the required type to set named properties.
The property names and values must match the class.

```powershell
$visibility = [AtlassianPS.JiraPS.Visibility]@{
    Type  = 'group'
    Value = 'jira-users'
}
Add-JiraIssueComment -Issue 'TEST-1' -Comment 'Team note' -Visibility $visibility
```

Constructing or changing an object only changes local data.
Use the command's update parameters to send changes to Jira.
For example, `Set-JiraVersion` uses the object to identify the version and its `Released` parameter to set the release flag.

```powershell
$version = [AtlassianPS.JiraPS.Version]@{ Id = '10200' }
Set-JiraVersion -Version $version -Released $true
```

## Passing objects to commands

Objects returned by one command can be passed to another command that accepts the same type.

```powershell
Get-JiraIssue -Query 'project = TEST AND status = "In Review"' |
    Add-JiraIssueComment -Comment 'Review sign-off complete.'
```

Argument transformers also accept identifier shorthand on supported parameters.
For example, `Add-JiraIssueComment -Issue 'TEST-1'` constructs an issue identifier object during parameter binding.
Version, filter and project transformers accept numeric IDs where the consuming parameter supports them.
Check the command's parameter help for accepted input forms and whether it requires an ID or can resolve a name.
Use explicit IDs when names are ambiguous.

## Identity and display

The six classes listed above compare instances of the same class using these properties.
Comparisons are case-insensitive.

| Class | Identity used for equality and ordering |
| ----- | -------------------------------------- |
| `AtlassianPS.JiraPS.Issue` | `Key` |
| `AtlassianPS.JiraPS.Version` | `Id`, falling back to `Name` |
| `AtlassianPS.JiraPS.Filter` | `Id` |
| `AtlassianPS.JiraPS.Project` | `Key` |
| `AtlassianPS.JiraPS.User` | `AccountId`, falling back to `Name` |
| `AtlassianPS.JiraPS.Group` | `Name` |

Use populated identity properties for equality checks, `Sort-Object -Unique` and hashtable keys.
Separate objects without an identity do not compare as equal.
Avoid changing an object's identity while using it as a hashtable key.

`ToString()` produces display text specific to the class.
For example, an issue includes its key and summary, while a version displays its name.
Read `Key`, `Id`, `AccountId` or another explicit property when a script needs an identifier.

## Nested properties and collections

Returned objects contain typed nested properties.
Common examples include:

| Property | Type |
| -------- | ---- |
| Issue `Assignee` | `AtlassianPS.JiraPS.User` or `$null` |
| Issue `Status` | `AtlassianPS.JiraPS.Status` |
| Issue `History` | `AtlassianPS.JiraPS.IssueHistoryEntry[]` |
| History entry `Items` | `AtlassianPS.JiraPS.IssueHistoryItem[]` |
| Issue `FixVersions` and `Versions` | `AtlassianPS.JiraPS.Version[]` |
| Issue `Components` | `AtlassianPS.JiraPS.Component[]` |
| Issue `Worklog` | `AtlassianPS.JiraPS.Worklogitem[]` |
| Comment or worklog `Visibility` | `AtlassianPS.JiraPS.Visibility` |
| Field `Schema` | `AtlassianPS.JiraPS.FieldSchema` |
| Remote link `RemoteObject` | `AtlassianPS.JiraPS.RemoteLinkObject` |

An unassigned issue has `$null` in `Assignee`.
Request history with `Get-JiraIssue -IncludeHistory`; `History` is `$null` when the response has no changelog.
For array-valued properties, present empty collections are empty typed arrays.
Optional nested objects and nullable properties can be `$null` when the response omits them.

```powershell
$issue = Get-JiraIssue -Key 'TEST-1' -IncludeHistory
if ($null -eq $issue.Assignee) {
    'This issue is unassigned.'
}
foreach ($entry in $issue.History) {
    foreach ($item in $entry.Items) {
        '{0}: {1} -> {2}' -f $item.Field, $item.FromString, $item.ToString
    }
}
```

Some properties use nullable enums, including user `AccountType`, component `AssigneeType` and filter permission `Type`.
An unrecognized API value for one of these enum properties becomes `$null`.

Custom issue fields are accessible as additional properties on the returned issue, such as `$issue.customfield_10001`.
Their values, entity-property values and allowed field values retain the data supplied by Jira.
Use explicit property access rather than formatted output when processing returned data.

# SEE ALSO

- [Get-JiraIssue](../commands/Get-JiraIssue/)
- [Add-JiraIssueComment](../commands/Add-JiraIssueComment/)
- [Set-JiraVersion](../commands/Set-JiraVersion/)
- [about_JiraPS_MigrationV3](migration-v3.html)
