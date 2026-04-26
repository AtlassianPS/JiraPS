---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Add-JiraGroupMember/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Add-JiraGroupMember/
---
# Add-JiraGroupMember

## SYNOPSIS

Adds a user to a JIRA group

## SYNTAX

```powershell
Add-JiraGroupMember [-Group] <Group[]> [-UserName] <User[]> [[-Credential] <pscredential>]
 [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function adds a JIRA user to a JIRA group.

## EXAMPLES

### EXAMPLE 1

```powershell
Add-JiraGroupMember -Group testUsers -User jsmith
```

This example adds the user "jsmith" to the group "testUsers"

### EXAMPLE 2

```powershell
Get-JiraGroup 'Project Admins' | Add-JiraGroupMember -User jsmith
```

This example illustrates the use of the pipeline to add "jsmith" to the
"Project Admins" group in JIRA.

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

Credentials to use to connect to JIRA.
If not specified, this function will use anonymous access.

```yaml
Type: PSCredential
DefaultValue: '[System.Management.Automation.PSCredential]::Empty'
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

Group (or list of groups) to which the user(s) will be added.

```yaml
Type: Group[]
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

### -UserName

Username or user object obtained from Get-JiraUser.

```yaml
Type: User[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
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

### JiraPS.Group

Group(s) to which users should be added

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

[Get-JiraGroup](../Get-JiraGroup/)

[Get-JiraGroupMember](../Get-JiraGroupMember/)

[Get-JiraUser](../Get-JiraUser/)

[New-JiraGroup](../New-JiraGroup/)

[New-JiraUser](../New-JiraUser/)

[Remove-JiraGroupMember](../Remove-JiraGroupMember/)

[Remove-JiraIssue](../Remove-JiraIssue/)

[Set-JiraIssue](../Set-JiraIssue/)
