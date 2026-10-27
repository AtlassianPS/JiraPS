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

```powershell
Find-JiraFilter [-Name <String[]>] [-AccountId <String>] [-GroupName <String>] [-Project <AtlassianPS.JiraPS.Project>] [-Fields <String[]>] [-Sort <String>] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>] [<CommonParameters>]
```

### ByOwner

```powershell
Find-JiraFilter [-Name <String[]>] [-Owner <AtlassianPS.JiraPS.User>] [-GroupName <String>] [-Project <AtlassianPS.JiraPS.Project>] [-Fields <String[]>] [-Sort <String>] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>] [<CommonParameters>]
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

Friendly connection name, unique without case sensitivity within Jira.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
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
AcceptedValues:
- description
- favourite_count
- is_favourite
- id
- name
- owner
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

## OUTPUTS

### AtlassianPS.JiraPS.Filter

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[Get-JiraFilter](../Get-JiraFilter/)

[Get-JiraProject](../Get-JiraProject/)

[Get-JiraUser](../Get-JiraUser/)
