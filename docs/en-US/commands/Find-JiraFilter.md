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

Find JIRA filter(s).

## SYNTAX

### ByAccountId (Default)

```powershell
Find-JiraFilter [-Name <string[]>] [-AccountId <string>] [-GroupName <string>] [-Project <Project>]
 [-Fields <string[]>] [-Sort <string>] [-Credential <pscredential>] [-IncludeTotalCount]
 [-Skip <ulong>] [-First <ulong>] [<CommonParameters>]
```

### ByOwner

```powershell
Find-JiraFilter [-Name <string[]>] [-Owner <User>] [-GroupName <string>] [-Project <Project>]
 [-Fields <string[]>] [-Sort <string>] [-Credential <pscredential>] [-IncludeTotalCount]
 [-Skip <ulong>] [-First <ulong>] [<CommonParameters>]
```

## DESCRIPTION

Searches for filters.
This operation is similar to Get filters except that the results can be refined to include filters that have specific attributes.
For example, filters with a particular name.
When multiple attributes are specified only filters matching all attributes are returned.

Disclaimer

> This works with Jira Cloud only.
 It does not work with non-cloud Jira Server (v8.3.1 at the time of this writing).

## EXAMPLES

### EXAMPLE 1

```powershell
Find-JiraFilter -Name 'ABC'
```

This example finds all JIRA filters that include ABC in the name.
 The search is case insensitive.

### EXAMPLE 2

```powershell
Find-JiraFilter -Name """George Jetsons Filter"""
```

This example finds a JIRA filter by exact name (case insensitive)

### EXAMPLE 3

```powershell
'My','Your' | Find-JiraFilter
```

This example demonstrates use of the pipeline to search for multiple filter Name(s).
 The search is case insensitive.

### EXAMPLE 4

```powershell
Find-JiraFilter -Name 'My','Your'
```

This example demonstrates the use of a list of names to search for multiple filter Name(s).
 The search is case insensitive.

### EXAMPLE 5

```powershell
Find-JiraFilter -AccountId 'c62dde3418235be1c8424950' -First 3 -Skip 3
```

This example finds all JIRA filters belonging to a specific owner, and illustrates the use of the -First and -Skip Paging parameters.

### EXAMPLE 6

```powershell
Find-JiraFilter -Project 'TEST' -First 8
```

This example finds all JIRA filters belonging to project TEST.

### Example 7

```powershell
Find-JiraFilter -Name """George Jetsons Filter""" -Fields 'description','jql'
```

This example finds the JIRA filter named "George Jetsons Filter" but only expands the fields listed.

By retrieving only the data really needed, the payload the server sends is
reduced, which speeds up the search.

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

### -Credential

Credentials to use to connect to JIRA.
If not specified, this function will use anonymous access.

```yaml
Type: PSCredential
DefaultValue: '[System.Management.Automation.PSCredential]::Empty'
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

Field you would like to select from your issue.
By default, all fields are
returned.

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
AcceptedValues:
- description
- favourite
- favouritedCount
- jql
- owner
- searchUrl
- sharePermissions
- subscriptions
- viewUrl
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

User Object or user name used to return filters with the matching owner.accountId.

```yaml
Type: User
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

The ID or Key of the Project to search.

```yaml
Type: Project
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

### -Sort

Orders the results using one of these filter properties:

- *description* Orders by filter description.
Note that this ordering works independently of whether the expand to display the description field is in use.
- *favourite_count* Orders by favouritedCount.
- *is_favourite* Orders by favourite.
- *id* Orders by filter id.
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
AcceptedValues:
- description
- favourite_count
- is_favourite
- id
- name
- owner
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### AtlassianPS.JiraPS.Filter

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraFilter](../Get-JiraFilter/)

[Get-JiraProject](../Get-JiraProject/)

[Get-JiraUser](../Get-JiraUser/)
