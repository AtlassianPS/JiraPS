---
document type: cmdlet
external help file: JiraPS-help.xml
HelpUri: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueWorklog/
Locale: en-DE
Module Name: JiraPS
ms.date: 04.22.2026
PlatyPS schema version: 2024-05-01
title: Get-JiraIssueWorklog
---

# Get-JiraIssueWorklog

## SYNOPSIS

Returns worklogs from an issue in JIRA.
****

## SYNTAX

### __AllParameterSets

```
Get-JiraIssueWorklog [-Issue] <Object> [[-Credential] <pscredential>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function obtains worklogs from existing issues in JIRA.

## EXAMPLES

### EXAMPLE 1

Get-JiraIssueWorklog -Key TEST-001


This example returns all worklogs from issue TEST-001.

### EXAMPLE 2

Get-JiraIssue TEST-002 | Get-JiraIssueWorklog


This example illustrates use of the pipeline to return all worklogs from issue TEST-002.

## PARAMETERS

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
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Issue

JIRA issue to check for worklogs.

Can be a `JiraPS.Issue` object, issue key, or internal issue ID.

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Key
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

### JiraPS.Issue / String

{{ Fill in the Description }}

### System.Object

{{ Fill in the Description }}

## OUTPUTS

### JiraPS.WorklogItem

{{ Fill in the Description }}

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.


## RELATED LINKS

- [Online Version](https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueWorklog/)
- [Add-JiraIssueWorklog](../Add-JiraIssueWorklog/)
- [Get-JiraIssue](../Get-JiraIssue/)
