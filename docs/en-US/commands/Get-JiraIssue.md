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

### ByIssueKey (Default)

```powershell
Get-JiraIssue -Key <String[]> [-Fields <String[]>] [-Credential <PSCredential>] [-IncludeHistory] [-Connection <AtlassianPS.Connection>] [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>] [<CommonParameters>]
```

### ByInputObject

```powershell
Get-JiraIssue -InputObject <AtlassianPS.JiraPS.Issue> [-Fields <String[]>] [-Credential <PSCredential>] [-IncludeHistory] [-Connection <AtlassianPS.Connection>] [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>] [<CommonParameters>]
```

### ByJQL

```powershell
Get-JiraIssue -Query <String> [-Fields <String[]>] [-PageSize <UInt32>] [-Credential <PSCredential>] [-IncludeHistory] [-Connection <AtlassianPS.Connection>] [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>] [<CommonParameters>]
```

### ByFilter

```powershell
Get-JiraIssue -Filter <AtlassianPS.JiraPS.Filter> [-Fields <String[]>] [-PageSize <UInt32>] [-Credential <PSCredential>] [-IncludeHistory] [-Connection <AtlassianPS.Connection>] [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>] [<CommonParameters>]
```

## DESCRIPTION

This function retrieves the data of a issue in Jira.

This function can be used to directly query Jira for a specific issue key or internal issue ID.
It can also be used to query Jira for issues matching a specific criteria using JQL (Jira Query Language).
Use `-IncludeHistory` to request changelog expansion and include issue history entries in the returned issue object.

> For more details on JQL syntax, see this article from Atlassian: [Atlassian's JQL reference](https://confluence.atlassian.com/display/JIRA/Advanced+Searching)

Output from this function can be piped to various other functions in this module, including `Set-JiraIssue`, `Add-JiraIssueComment`, and `Invoke-JiraIssueTransition`.

## EXAMPLES

### Example 1

```powershell
Get-JiraIssue -Key TEST-001
```

This example fetches the issue "TEST-001".

The default `Format-Table` view of a Jira issue only shows the value of `Key`, `Summary`, `Status` and `Created`.
> This can be manipulated with `Format-Table`, `Format-List` and `Select-Object`

### Example 2

```powershell
Get-JiraIssue 'TEST-002' | Add-JiraIssueComment 'Test comment from PowerShell'
```

This example illustrates pipeline use from `Get-JiraIssue` to `Add-JiraIssueComment`.

### Example 3

```powershell
Get-JiraIssue -Query 'project = "TEST" AND created >= -5d'
```

This example illustrates using the `-Query` parameter and JQL syntax to query Jira for matching issues.

### Example 4

```powershell
Get-JiraIssue -InputObject $oldIssue
```

This example illustrates how to get an update of an issue from an old result of `Get-JiraIssue` stored in $oldIssue.

### Example 5

```powershell
Get-JiraIssue TEST-001 | Get-JiraIssue
```

This example shows how to refresh issue data by piping an existing issue object back to `Get-JiraIssue`.
The `-Key` parameter accepts pipeline input by property name, so the `Key` property from the piped issue is used.

### Example 6

```powershell
Get-JiraFilter -Id 12345 | Get-JiraIssue
```

This example retrieves all issues that match the criteria in the saved filter with ID 12345.

### Example 7

```powershell
Get-JiraFilter 12345 | Get-JiraIssue | Select-Object *
```

This prints all fields of the issue to the console.

### Example 8

```powershell
Get-JiraIssue -Query 'project = TEST' -Fields 'key', 'summary', 'assignee'
```

This example retrieves all issues in project "TEST" - but only the 3 properties listed above: key, summary and assignee

By retrieving only the data really needed, the payload the server sends is reduced, which speeds up the query.

## PARAMETERS

### -Credential

Username/password or compatible Cloud email/token as PSCredential.
Explicit input temporarily overrides the selected identity without inheriting cookies or changing the stored connection.
An empty credential fails; omitted input uses the selected connection.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
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

An existing Jira filter whose results are returned.

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

### -First

Indicates how many items to return.

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

### -IncludeTotalCount

Causes an extra output of the total count at the beginning.

Note this is actually a uInt64, but with a custom string representation.

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

### -InputObject

An existing issue to retrieve.

```yaml
Type: AtlassianPS.JiraPS.Issue
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByInputObject
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Key

Key of the issue to search for.

```yaml
Type: String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Issue
ParameterSets:
- Name: ByIssueKey
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PageSize

How many issues should be returned per call to Jira.

Normally, you should not need to adjust this parameter, but if the REST calls take a long time, try playing with different values here.

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

Controls how many things will be skipped before starting output.

Defaults to 0.

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

### -Connection

Active Jira connection for this operation.
Session is a compatibility alias.
When omitted, the command uses the selected Jira default.
Use Get-JiraConnection -Name to resolve a named connection.

```yaml
Type: AtlassianPS.Connection
Parameter Sets: (All)
Aliases: Session

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable.
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.Issue / String

The `-Key` parameter accepts pipeline input by property name.
This means:

- If an `AtlassianPS.JiraPS.Issue` object is piped, its `Key` property is bound to the `-Key` parameter.
- If a String is passed, this function searches for an issue with that issue key or internal ID.
- If an object with a `Key` property is piped, that property value is used.

This enables patterns like `Get-JiraIssue TEST-1 | Get-JiraIssue` to refresh issue data.

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
