---
document type: cmdlet
external help file: JiraPS-help.xml
HelpUri: https://atlassianps.org/docs/JiraPS/commands/Get-JiraSession/
Locale: en-DE
Module Name: JiraPS
ms.date: 04.22.2026
PlatyPS schema version: 2024-05-01
title: Get-JiraSession
---

# Get-JiraSession

## SYNOPSIS

Obtains a reference to the currently saved JIRA session

## SYNTAX

### __AllParameterSets

```
Get-JiraSession [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function obtains a reference to the currently saved JIRA session.

This can provide a JIRA session ID, as well as the username used to connect to JIRA.

## EXAMPLES

### EXAMPLE 1

New-JiraSession -Credential (Get-Credential jiraUsername)
Get-JiraSession


Creates a Jira session for jiraUsername, then obtains a reference to it.

## PARAMETERS

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### JiraPS.Session

{{ Fill in the Description }}

## NOTES




## RELATED LINKS

- [Online Version](https://atlassianps.org/docs/JiraPS/commands/Get-JiraSession/)
- [about_JiraPS_Authentication](../../about/authentication.html)
- [New-JiraSession](../New-JiraSession/)
