---
document type: cmdlet
external help file: JiraPS-help.xml
HelpUri: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraGroupMember/
Locale: en-DE
Module Name: JiraPS
ms.date: 04.22.2026
PlatyPS schema version: 2024-05-01
title: Remove-JiraGroupMember
---

# Remove-JiraGroupMember

## SYNOPSIS

Removes a user from a JIRA group

## SYNTAX

### __AllParameterSets

```
Remove-JiraGroupMember [-Group] <Object[]> [-User] <Object[]> [[-Credential] <pscredential>]
 [-PassThru] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function removes a JIRA user from a JIRA group.

## EXAMPLES

### EXAMPLE 1

Remove-JiraGroupMember -Group testUsers -User jsmith


This example removes the user jsmith from the group testUsers.

### EXAMPLE 2

Get-JiraGroup 'Project Admins' | Remove-JiraGroupMember -User jsmith


This example illustrates the use of the pipeline to remove jsmith from the "Project Admins" group in JIRA.

## PARAMETERS

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
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

Credentials to use to connect to JIRA.
If not specified, this function will use anonymous access.

```yaml
Type: System.Management.Automation.PSCredential
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

### -Force

Suppress user confirmation.

```yaml
Type: System.Management.Automation.SwitchParameter
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

Group Object or ID from which to remove the user(s).

```yaml
Type: System.Object[]
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

Whether output should be provided after invoking this function

```yaml
Type: System.Management.Automation.SwitchParameter
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

Username or user object obtained from Get-JiraUser

```yaml
Type: System.Object[]
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
Type: System.Management.Automation.SwitchParameter
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

### JiraPS.Group

Group(s) from which users should be removed

### JiraPS.User

User(s) which to remove

### System.Object[]

{{ Fill in the Description }}

## OUTPUTS

### JiraPS.Group

If the `-PassThru` parameter is provided, this function will provide a reference to the JIRA group modified.
Otherwise, this function does not provide output.

## NOTES

This REST method is still marked Experimental in JIRA's REST API.
That means that there is a high probability this will break in future versions of JIRA.
The function will need to be re-written at that time.

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.


## RELATED LINKS

- [Online Version](https://atlassianps.org/docs/JiraPS/commands/Remove-JiraGroupMember/)
- [Add-JiraGroupMember](../Add-JiraGroupMember/)
- [Get-JiraGroup](../Get-JiraGroup/)
- [Get-JiraGroupMember](../Get-JiraGroupMember/)
- [Get-JiraUser](../Get-JiraUser/)
- [New-JiraGroup](../New-JiraGroup/)
