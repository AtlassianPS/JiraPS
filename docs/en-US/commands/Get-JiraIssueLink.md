---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueLink/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueLink/
---
# Get-JiraIssueLink

## SYNOPSIS

Returns a specific issueLink from Jira

## SYNTAX

```powershell
Get-JiraIssueLink [-Id] <int[]> [[-Credential] <pscredential>] [<CommonParameters>]
```

## DESCRIPTION

This function returns information regarding a specified issueLink from Jira.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraIssueLink 10000
```

Returns information about the IssueLink with ID 10000

### EXAMPLE 2

```powershell
Get-JiraIssueLink -IssueLink 10000
```

Returns information about the IssueLink with ID 10000

### EXAMPLE 3

```powershell
(Get-JiraIssue TEST-01).issuelinks | Get-JiraIssueLink
```

Returns the information about all IssueLinks in issue TEST-01

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

### -Id

The IssueLink ID to search.

Accepts input from pipeline when the object is of type `JiraPS.IssueLink`

```yaml
Type: System.Int32[]
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Int


### System.Int32[]

## OUTPUTS

### JiraPS.IssueLink

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Add-JiraIssueLink](../Add-JiraIssueLink/)

[Get-JiraIssueLinkType](../Get-JiraIssueLinkType/)

[Remove-JiraIssueLink](../Remove-JiraIssueLink/)
