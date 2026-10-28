---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/New-JiraUser/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/New-JiraUser/
---
# New-JiraUser

## SYNOPSIS

Creates a new user in JIRA

## SYNTAX

```
New-JiraUser [-EmailAddress] <string> [[-UserName] <string>] [[-DisplayName] <string>]
 [[-Products] <string[]>] [[-Connection] <AtlassianPS.Connection>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

Creates users through the deployment-specific Jira API.
Cloud requires EmailAddress and an explicit Products array.
Data Center requires EmailAddress and UserName, with optional DisplayName.
Cloud rejects Data Center-only parameters; Data Center rejects Products.
Returns the typed user from the creation response without a follow-up lookup.
Invitation behavior is controlled by Atlassian or Jira; no Boolean notification flag is sent.

## EXAMPLES

### Example 1

```powershell
New-JiraUser -EmailAddress 'me@example.com' -Products jira-software -Connection $cloud
```

Create a Cloud user with Jira Software access.

### Example 2

```powershell
New-JiraUser -EmailAddress 'me@example.com' -Products @() -Connection $cloud
```

Create a Cloud user without product access.

### Example 3

```powershell
New-JiraUser -EmailAddress 'me@example.com' -UserName me -DisplayName 'My Name' -Connection $dataCenter
```

Create a Data Center user with an explicit username and display name.

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
  Position: 4
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -DisplayName

Data Center display name.
When omitted, Data Center uses UserName.
This parameter is unavailable on Cloud.

```yaml
Type: String
DefaultValue: ''
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

### -EmailAddress

Email address of the user to create.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Email
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Products

Explicit Cloud product access list.
Use @() to request no product access.
This parameter is unavailable on Data Center.

```yaml
Type: String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 3
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -UserName

Required username for Data Center.
This parameter is unavailable on Cloud.

```yaml
Type: String
DefaultValue: ''
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

None.

## OUTPUTS

### AtlassianPS.JiraPS.User

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraUser](../Get-JiraUser/)

[Remove-JiraUser](../Remove-JiraUser/)
