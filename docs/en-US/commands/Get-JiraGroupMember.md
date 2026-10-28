---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraGroupMember/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraGroupMember/
---
# Get-JiraGroupMember

## SYNOPSIS

Returns members of a given group in Jira.

## SYNTAX

```
Get-JiraGroupMember [-Group] <AtlassianPS.JiraPS.Group[]> [[-PageSize] <uint>] [[-Connection] <AtlassianPS.Connection>]
 [-IncludeInactive] [-IncludeTotalCount] [-Skip <ulong>] [-First <ulong>] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

This function returns members of a provided group in Jira.

On Jira Cloud, the cmdlet uses the group's `Id` for member lookup when the input group already includes one.
Otherwise, it uses the group name directly.
On Jira Data Center, it uses the documented `groupname` lookup path.
You can pass a group name directly.
That is usually more reliable than resolving the group first with `Get-JiraGroup`, especially on Jira Data Center where canonical group lookup may fail while member lookup by name still works.

## EXAMPLES

### Example 1

```powershell
Get-JiraGroupMember testGroup
```

This example returns all members of the Jira group testGroup.

### Example 2

```powershell
Get-JiraGroupMember -Group 'Developers'
```

This example returns the members of the Developers group without first resolving the group through `Get-JiraGroup`.

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
  Position: 2
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

### -Group

Group object of which to display the members.

If the group object includes `Id`, that identifier is used automatically on Jira Cloud.
Passing a plain group name is supported and is the most portable option across Jira deployments.

```yaml
Type: AtlassianPS.JiraPS.Group[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IncludeInactive

Include inactive users in the results.

By default they are not shown.

```yaml
Type: SwitchParameter
DefaultValue: False
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

### -PageSize

Number of records requested per page.
Use First to limit output and Skip to skip records.

```yaml
Type: UInt32
DefaultValue: 25
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: false
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

### AtlassianPS.JiraPS.Group[]

## OUTPUTS

### AtlassianPS.JiraPS.User

## NOTES

By default, this will return all active users who are members of the given group.
For large groups, this can take quite some time.

To limit the number of group members returned, use the `-First` parameter.
You can also combine this with the `-Skip` parameter to "page" through results.

This function does not return inactive users.
This appears to be a limitation of Jira's REST API.

On Jira Data Center, prefer `Get-JiraGroupMember -Group '<name>'` over `Get-JiraGroup '<name>' | Get-JiraGroupMember` unless you already have a resolved group object.

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraGroup](../Get-JiraGroup/)

[Add-JiraGroupMember](../Add-JiraGroupMember/)

[New-JiraGroup](../New-JiraGroup/)

[New-JiraUser](../New-JiraUser/)

[Remove-JiraGroupMember](../Remove-JiraGroupMember/)
