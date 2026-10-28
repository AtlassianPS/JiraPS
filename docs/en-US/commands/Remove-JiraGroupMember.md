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
Remove-JiraGroupMember [-Group] <AtlassianPS.JiraPS.Group[]> [-User] <AtlassianPS.JiraPS.User[]> [[-Credential] <pscredential>] [[-Connection] <AtlassianPS.Connection>] [-PassThru] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
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

### -Credential

Username/password or compatible Cloud email/token as PSCredential.
Explicit input temporarily overrides the selected identity without inheriting cookies or changing the stored connection.
An empty credential fails; omitted input uses the selected connection.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: None

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force

Suppress user confirmation.

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

Username or user object obtained from Get-JiraUser.

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
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable.
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.Group

Group(s) from which users should be removed

### AtlassianPS.JiraPS.User

User(s) which to remove

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
