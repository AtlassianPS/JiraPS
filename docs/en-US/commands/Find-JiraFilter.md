---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Find-JiraFilter/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Find-JiraFilter/
---
# Find-JiraFilter

## SYNOPSIS

Find Jira filter(s).

## SYNTAX

### ByAccountId (Default)

```
Find-JiraFilter [-Name <string[]>] [-AccountId <string>] [-GroupName <string>] [-Project <AtlassianPS.JiraPS.Project>]
 [-Fields <string[]>] [-Sort <string>] [-Connection <AtlassianPS.Connection>] [-IncludeTotalCount]
 [-Skip <ulong>] [-First <ulong>] [<CommonParameters>]
```

### ByOwner

```
Find-JiraFilter [-Name <string[]>] [-Owner <AtlassianPS.JiraPS.User>] [-GroupName <string>] [-Project <AtlassianPS.JiraPS.Project>]
 [-Fields <string[]>] [-Sort <string>] [-Connection <AtlassianPS.Connection>] [-IncludeTotalCount]
 [-Skip <ulong>] [-First <ulong>] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

Searches Jira Cloud filters using explicit criteria.
Owner uses the exact accountId.
Data Center does not expose this filter-search API; use Get-JiraFilter -Filter or -Favorite.

## EXAMPLES

### Example 1

```powershell
Find-JiraFilter -Name 'ABC'
```

This example finds all Jira filters that include ABC in the name.
The search is case insensitive.

### Example 2

```powershell
Find-JiraFilter -Name '''George Jetsons Filter'''
```

This example finds a Jira filter by exact name (case insensitive)

### Example 3

```powershell
'My','Your' | Find-JiraFilter
```

This example demonstrates use of the pipeline to search for multiple filter names.
The search is case insensitive.

### Example 4

```powershell
Find-JiraFilter -Name 'My','Your'
```

This example demonstrates the use of a list of names to search for multiple filter names.
The search is case insensitive.

### Example 5

```powershell
Find-JiraFilter -AccountId 'c62dde3418235be1c8424950' -First 3 -Skip 3
```

This example finds all Jira filters belonging to a specific owner, and illustrates the use of the -First and -Skip Paging parameters.

### Example 6

```powershell
Find-JiraFilter -Project 'TEST' -First 8
```

This example finds all Jira filters belonging to project TEST.

### Example 7

```powershell
Find-JiraFilter -Name '''George Jetsons Filter''' -Fields 'description','jql'
```

This example finds the Jira filter named "George Jetsons filter" but only expands the fields listed.

By retrieving only the data really needed, the payload the server sends is reduced, which speeds up the search.

## PARAMETERS

### -AccountId

User AccountId used to return filters with the matching owner.accountId.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByAccountId
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

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

Fields to include in the returned filter.
By default, all fields are returned.

Allows any combination of the following values:

- description
- favourite
- favouritedCount
- jql
- owner
- searchUrl
- sharePermissions
- subscriptions
- viewUrl

```yaml
Type: String[]
DefaultValue: "'description','favourite','favouritedCount','jql','owner','searchUrl','sharePermissions','subscriptions','viewUrl'"
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

### -GroupName

Group name used to return filters that are shared with a group that matches sharePermissions.group.groupname.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
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

### -Name

String used to perform a case-insensitive partial match with name.
An exact match can be requested by including quotes (refer to the examples above).

```yaml
Type: String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Owner

User object or user name used to return filters with the matching owner.accountId.

```yaml
Type: AtlassianPS.JiraPS.User
DefaultValue: ''
SupportsWildcards: false
Aliases:
- UserName
ParameterSets:
- Name: ByOwner
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Project

The ID or key of the project to search.

```yaml
Type: AtlassianPS.JiraPS.Project
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
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

### -Sort

Orders the results using one of these filter properties:

- *description* Orders by filter description.
  Note that this ordering works independently of whether the expand to display the description field is in use.
- *favourite_count* Orders by favouritedCount.
- *is_favourite* Orders by favourite.
- *ID* Orders by filter ID.
- *name* Orders by filter name.
- *owner* Orders by owner.accountId.

```yaml
Type: String
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String[]

## OUTPUTS

### AtlassianPS.JiraPS.Filter

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraFilter](../Get-JiraFilter/)

[Get-JiraProject](../Get-JiraProject/)

[Get-JiraUser](../Get-JiraUser/)
