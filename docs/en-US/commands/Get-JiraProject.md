---
document type: cmdlet
external help file: JiraPS-help.xml
HelpUri: https://atlassianps.org/docs/JiraPS/commands/Get-JiraProject/
Locale: en-DE
Module Name: JiraPS
ms.date: 04.22.2026
PlatyPS schema version: 2024-05-01
title: Get-JiraProject
---

# Get-JiraProject

## SYNOPSIS

Returns a project from Jira

## SYNTAX

### _All (Default)

```
Get-JiraProject [-Credential <pscredential>] [<CommonParameters>]
```

### _Search

```
Get-JiraProject [-Project] <string[]> [-Credential <pscredential>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function returns information regarding a specified project from Jira.

If the Project parameter is not supplied, it will return information about all projects the given user is authorized to view.

The `-Project` parameter will accept either a project ID or a project key.

## EXAMPLES

### EXAMPLE 1

Get-JiraProject -Project TEST -Credential $cred


Returns information about the project TEST

### EXAMPLE 2

Get-JiraProject 2 -Credential $cred


Returns information about the project with ID 2

### EXAMPLE 3

Get-JiraProject


Returns information about all projects the user is authorized to view

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

### -Project

The Project ID or project key of a project to search.

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

### System.String[]

{{ Fill in the Description }}

## OUTPUTS

### JiraPS.Project

{{ Fill in the Description }}

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

Remaining operations for `project` have not yet been implemented in the module.


## RELATED LINKS

- [Online Version](https://atlassianps.org/docs/JiraPS/commands/Get-JiraProject/)
