---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraGroup/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraGroup/
---
# Get-JiraGroup

## SYNOPSIS

Returns a group from Jira

## SYNTAX

```powershell
Get-JiraGroup [-GroupName] <string[]> [[-Credential] <pscredential>] [<CommonParameters>]
```

## DESCRIPTION

This function returns information regarding a specified group from JIRA.

To get the members of a group, use `Get-JiraGroupMember`.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraGroup -GroupName testGroup
```

Returns information about the group "testGroup"

### EXAMPLE 2

```powershell
Get-JiraGroup -GroupName testGroup |
    Get-JiraGroupMember
```

This example retrieves the members of "testGroup".

## PARAMETERS

### -Credential

Credentials to use to connect to JIRA.
If not specified, this function will use anonymous access.

```yaml
Type: System.Management.Automation.PSCredential
DefaultValue: '[System.Management.Automation.PSCredential]::Empty'
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

### -GroupName

Name of the group to search for.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Name
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String[]

## OUTPUTS

### JiraPS.Group

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraGroupMember](../Get-JiraGroupMember/)

[Get-JiraUser](../Get-JiraUser/)

[New-JiraGroup](../New-JiraGroup/)

[Remove-JiraGroup](../Remove-JiraGroup/)
