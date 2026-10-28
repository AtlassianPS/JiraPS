---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraGroupMember/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Remove-JiraGroupMember/
---
# Remove-JiraGroupMember

## SYNOPSIS

Removes a user from a Jira group.

## SYNTAX

```powershell
Remove-JiraGroupMember [-Group] <AtlassianPS.JiraPS.Group[]> [-User] <AtlassianPS.JiraPS.User[]> [[-Connection] <AtlassianPS.Connection>] [-PassThru]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function removes a Jira user from a Jira group.
Pass the group name directly when you already know it.
That avoids depending on `Get-JiraGroup`, whose canonical lookup path is less reliable on Jira Data Center.

## EXAMPLES

### Example 1

```powershell
Remove-JiraGroupMember -Group testUsers -User jsmith
```

This example removes the user jsmith from the group testUsers.

### Example 2

```powershell
Remove-JiraGroupMember -Group 'Project Admins' -User jsmith
```

This example removes jsmith from the `Project Admins` group without first resolving the group through `Get-JiraGroup`.

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
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Group

Group object or name from which to remove the user(s).
Passing a group name is the most portable option across Jira Cloud and Jira Data Center.

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

### -PassThru

Whether output should be provided after invoking this function.

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

### -User

Exact user identifiers or typed user objects.
Cloud strings are literal account IDs; Data Center strings are literal usernames.

```yaml
Type: AtlassianPS.JiraPS.User[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- UserName
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: true
  ValueFromPipeline: false
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

### AtlassianPS.JiraPS.Group

If the `-PassThru` parameter is provided, this function will provide a reference to the Jira group modified.
Otherwise, this function does not provide output.

## NOTES

This REST method is still marked Experimental in Jira's REST API.
That means that there is a high probability this will break in future versions of Jira.
The function will need to be re-written at that time.

On Jira Data Center, do not treat `Get-JiraGroup` as a prerequisite for this cmdlet.
If you already know the group name, pass it directly.

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Add-JiraGroupMember](../Add-JiraGroupMember/)

[Get-JiraGroup](../Get-JiraGroup/)

[Get-JiraGroupMember](../Get-JiraGroupMember/)

[Get-JiraUser](../Get-JiraUser/)

[New-JiraGroup](../New-JiraGroup/)
