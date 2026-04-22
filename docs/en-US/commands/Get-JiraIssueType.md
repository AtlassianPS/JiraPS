---
document type: cmdlet
external help file: JiraPS-help.xml
HelpUri: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueType/
Locale: en-DE
Module Name: JiraPS
ms.date: 04.22.2026
PlatyPS schema version: 2024-05-01
title: Get-JiraIssueType
---

# Get-JiraIssueType

## SYNOPSIS

Returns information about the available issue type in JIRA.

## SYNTAX

### _All (Default)

```
Get-JiraIssueType [-Force] [-Credential <pscredential>] [<CommonParameters>]
```

### _Search

```
Get-JiraIssueType [-IssueType] <string[]> [-Force] [-Credential <pscredential>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function retrieves all the available IssueType on the JIRA server an returns them as `JiraPS.IssueType`.

This function can restrict the output to a subset of the available IssueTypes if told so.

Results are cached for 60 minutes to improve performance.
Use `-Force` to bypass the cache and fetch fresh data.

## EXAMPLES

### EXAMPLE 1

Get-JiraIssueType


This example returns all the IssueTypes on the JIRA server.

### EXAMPLE 2

Get-JiraIssueType -IssueType "Bug"


This example returns only the IssueType "Bug".

### EXAMPLE 3

Get-JiraIssueType -IssueType "Bug","Task","4"


This example return the information about the IssueType named "Bug" and "Task" and with id "4".

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
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Force

Bypass the cache and fetch fresh data from the server.

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

### -IssueType

The Issue Type name or ID to search.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: _Search
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
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

### Int

{{ Fill in the Description }}

### System.String[]

{{ Fill in the Description }}

## OUTPUTS

### JiraPS.IssueType

{{ Fill in the Description }}

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.


## RELATED LINKS

- [Online Version](https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueType/)
- [Get-JiraIssue](../Get-JiraIssue/)
