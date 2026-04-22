---
document type: cmdlet
external help file: JiraPS-help.xml
HelpUri: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueLinkType/
Locale: en-DE
Module Name: JiraPS
ms.date: 04.22.2026
PlatyPS schema version: 2024-05-01
title: Get-JiraIssueLinkType
---

# Get-JiraIssueLinkType

## SYNOPSIS

Gets available issue link types

## SYNTAX

### _All (Default)

```
Get-JiraIssueLinkType [-Credential <pscredential>] [<CommonParameters>]
```

### _Search

```
Get-JiraIssueLinkType [-LinkType] <Object> [-Credential <pscredential>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function gets available issueLink types from a JIRA server.
It can also return specific information about a single issueLink type.

This is a useful function for discovering data about issueLink types in order to create and modify issueLinks on issues.

## EXAMPLES

### EXAMPLE 1

Get-JiraIssueLinkType


This example returns all available links from the JIRA server

### EXAMPLE 2

Get-JiraIssueLinkType -LinkType 1


This example returns information about the link type with ID 1.

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

### -LinkType

The Issue Type name or ID to search.

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: _Search
  Position: 0
  IsRequired: true
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

### Int

{{ Fill in the Description }}

## OUTPUTS

### JiraPS.IssueLinkType

{{ Fill in the Description }}

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

Remaining operations for `issuetype` have not yet been implemented in the module.


## RELATED LINKS

- [Online Version](https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueLinkType/)
- [Add-JiraIssueLink](../Add-JiraIssueLink/)
- [Get-JiraIssueLink](../Get-JiraIssueLink/)
- [Remove-JiraIssueLink](../Remove-JiraIssueLink/)
