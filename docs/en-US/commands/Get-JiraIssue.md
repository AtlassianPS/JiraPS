---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssue/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssue/
---
# Get-JiraIssue

## SYNOPSIS

Returns information about an issue in Jira.

## SYNTAX

### Issue (Default)

```powershell
Get-JiraIssue [-Issue] <AtlassianPS.JiraPS.Issue[]> [-Fields <string[]>] [-IncludeHistory] [-Connection <AtlassianPS.Connection>]
 [-IncludeTotalCount] [-Skip <ulong>] [-First <ulong>] [<CommonParameters>]
```

### ByJQL

```powershell
Get-JiraIssue -Query <string> [-Fields <string[]>] [-PageSize <uint>] [-IncludeHistory]
 [-Connection <AtlassianPS.Connection>] [-IncludeTotalCount] [-Skip <ulong>] [-First <ulong>] [<CommonParameters>]
```

### ByFilter

```powershell
Get-JiraIssue -Filter <AtlassianPS.JiraPS.Filter> [-Fields <string[]>] [-PageSize <uint>] [-IncludeHistory]
 [-Connection <AtlassianPS.Connection>] [-IncludeTotalCount] [-Skip <ulong>] [-First <ulong>] [<CommonParameters>]
```

## DESCRIPTION

This function retrieves issue data from Jira.

This function can be used to directly query Jira for a specific issue key or internal issue ID.
It can also be used to query Jira for issues matching specific criteria using JQL (Jira Query Language).
Use `-IncludeHistory` to request changelog expansion and include issue history entries in the returned issue object.

> For more details on JQL syntax, see this article from Atlassian: [Atlassian's JQL reference](https://confluence.atlassian.com/display/JIRA/Advanced+Searching)

Output from this function can be piped to various other functions in this module, including `Set-JiraIssue`, `Add-JiraIssueComment`, and `Invoke-JiraIssueTransition`.

## EXAMPLES

### Example 1: Retrieve an issue by key or ID

```powershell
Get-JiraIssue -Issue 'PROJ-1'

# Or use Jira's internal issue ID.
Get-JiraIssue -Issue '10001'
```

Retrieve a single issue using the selected connection.
`-Key` and `-Id` remain aliases for `-Issue`.

### Example 2: Retrieve several issues

```powershell
Get-JiraIssue -Issue 'PROJ-1', 'PROJ-2'
```

Retrieve each issue in the supplied list.
You can also pipe issue keys to `Get-JiraIssue`.

### Example 3: Search recently created issues with JQL

```powershell
Get-JiraIssue -Query 'project = PROJ AND created >= -5d ORDER BY created DESC'
```

Retrieve issues created in project PROJ during the last five days, newest first.
JQL and saved-filter searches automatically retrieve subsequent pages until all matches have been returned or `-First` is satisfied.

### Example 4: Retrieve issues from a saved filter

```powershell
Get-JiraIssue -Filter 12345

# Or pass a filter object explicitly.
$filter = Get-JiraFilter -Filter 12345
Get-JiraIssue -Filter $filter
```

Retrieve issues matching the saved filter's criteria.
Use `-Filter` for filter IDs and objects; pipeline input selects issues to retrieve.

### Example 5: Request only the fields you need

```powershell
Get-JiraIssue -Query 'project = PROJ' -Fields 'summary', 'assignee', 'status' |
    Select-Object Key, Summary, Assignee, Status
```

Limit the fields Jira sends to reduce the response payload.
The issue key and ID remain available; fields that were not requested may be empty in the returned object.
`Select-Object` chooses the output columns, while `-Fields` controls the request to Jira.

### Example 6: Inspect all returned issue properties

```powershell
Get-JiraIssue -Issue 'PROJ-1' | Format-List *
```

The default table view displays only a subset of the issue's properties.
Use `Format-List *` to inspect every returned property, or `Select-Object` to choose specific properties for further processing.

### Example 7: Refresh an existing issue object

```powershell
$issue = Get-JiraIssue -Issue 'PROJ-1'
Get-JiraIssue -Issue $issue

# Alternatively, pipe the existing issue object.
$issue | Get-JiraIssue
```

Fetch the current issue data again after changes made in Jira.
Assign the result back to `$issue` to replace the stored snapshot.

### Example 8: Add a comment through the pipeline

```powershell
Get-JiraIssue -Issue 'PROJ-1' |
    Add-JiraIssueComment -Comment 'Reviewed from PowerShell.'
```

Pass the retrieved issue to `Add-JiraIssueComment` to add a comment.
Both commands use the selected connection.

### Example 9: Limit search results and include their total count

```powershell
Get-JiraIssue -Query 'project = PROJ ORDER BY key' -Skip 20 -First 10 -PageSize 50 -IncludeTotalCount
```

Skip the first 20 matches and return up to 10 issues.
`-PageSize` controls the requested API page size; `-First` limits the number of issues returned.
Total-count information is emitted before the issue objects, with unknown accuracy when Jira does not supply a total.

### Example 10: Retrieve issue history

```powershell
$issue = Get-JiraIssue -Issue 'PROJ-1' -IncludeHistory
$issue.History | Format-List *
```

Request changelog expansion and inspect the returned history entries.
The entries are available through the issue's `History` property.

### Example 11: Use a named connection

```powershell
$work = Get-JiraConnection -Name work
Get-JiraIssue -Issue 'PROJ-1' -Connection $work
```

Retrieve an issue through the existing connection named work.
Pass the same `-Connection` to any downstream Jira command that should use that site and identity.

## PARAMETERS

### -Connection

Active Jira connection for this operation.
When omitted, the command uses the selected Jira default.
Create connections with Connect-Jira; resolve names with Get-JiraConnection -Name.

```yaml
Type: AtlassianPS.Connection
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Fields

Fields to include in the returned issue.
By default, all fields are returned.

Allowed values:

- `"*all"` - return all fields.
- `"*navigable"` - return navigable fields only.
- `"summary", "comment"` - return the summary and comments fields only.
- `"-comment"` - return all fields except comments.
- `"*all", "-comment"` - same as above

```yaml
Type: String[]
DefaultValue: '*all'
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Filter

A saved filter ID or typed filter object.
Pass it explicitly with `-Filter`.

```yaml
Type: AtlassianPS.JiraPS.Filter
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByFilter
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -First

Maximum number of matching records to return.

```yaml
Type: UInt64
DefaultValue: 18446744073709551615
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IncludeHistory

Requests changelog expansion when retrieving issues.
When set, the returned issue object includes a `History` property with the issue history entries.

```yaml
Type: SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases:
- GetHistory
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IncludeTotalCount

Return total-count information before the records.
Accuracy is unknown when Jira does not provide a total.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Issue

Issue keys, numeric ID strings or typed issue objects.

```yaml
Type: AtlassianPS.JiraPS.Issue[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Key
- Id
ParameterSets:
- Name: Issue
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PageSize

Number of records requested per page.
Use First to limit output and Skip to skip records.

```yaml
Type: UInt32
DefaultValue: 25
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByFilter
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: ByJQL
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Query

JQL query for which to search for.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- JQL
ParameterSets:
- Name: ByJQL
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Skip

Number of matching records to skip before returning output.

```yaml
Type: UInt64
DefaultValue: 0
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.Issue[]

Accepts issue keys, numeric ID strings, issue objects, and objects with a `Key` or `Id` property.
Pipe an existing issue object back to `Get-JiraIssue` to retrieve its current data.

## OUTPUTS

### AtlassianPS.JiraPS.Issue

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[about_JiraPS_CreatingIssues](../../about/creating-issues.html)

[about_JiraPS_CustomFields](../../about/custom-fields.html)

[New-JiraIssue](../New-JiraIssue/)
