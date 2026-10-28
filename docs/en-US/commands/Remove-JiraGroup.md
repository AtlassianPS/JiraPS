---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraGroup/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Remove-JiraGroup/
---
# Remove-JiraGroup

## SYNOPSIS

Removes an existing group from Jira.

## SYNTAX

```powershell
Remove-JiraGroup [-Group] <AtlassianPS.JiraPS.Group[]> [[-Connection] <AtlassianPS.Connection>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function removes an existing group from Jira.

On Jira Cloud, the cmdlet deletes by `Id` when the input group already includes one.
Otherwise, it deletes by group name.
On Jira Data Center, it uses the documented `groupname` deletion path.
Passing the group name directly is usually more reliable than resolving the group first with `Get-JiraGroup`.

> Deleting a group does not delete users from Jira.

## EXAMPLES

### Example 1

```powershell
Remove-JiraGroup -GroupName testGroup
```

Removes the Jira group testGroup

## PARAMETERS

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
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
When omitted, the command uses the selected Jira default.
Create connections with Connect-Jira; resolve names with Get-JiraConnection -Name.

```yaml
Type: AtlassianPS.Connection
DefaultValue: None
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

### -Group

Group object or name to delete.
On Jira Cloud, `Id` is used automatically when the input object already includes one.
On Jira Data Center, passing the group name directly avoids depending on `Get-JiraGroup`.

```yaml
Type: AtlassianPS.JiraPS.Group[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- GroupName
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
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

None.

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

`Remove-JiraGroup` can still work on Jira Data Center even when `Get-JiraGroup` cannot resolve the same group.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraGroup](../Get-JiraGroup/)

[New-JiraGroup](../New-JiraGroup/)
