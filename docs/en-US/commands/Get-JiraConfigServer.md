---
document type: cmdlet
external help file: JiraPS-help.xml
HelpUri: https://atlassianps.org/docs/JiraPS/commands/Get-JiraConfigServer/
Locale: en-DE
Module Name: JiraPS
ms.date: 04.22.2026
PlatyPS schema version: 2024-05-01
title: Get-JiraConfigServer
---

# Get-JiraConfigServer

## SYNOPSIS

Obtains the configured URL for the JIRA server

## SYNTAX

### __AllParameterSets

```
Get-JiraConfigServer [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function returns the configured URL for the JIRA server that JiraPS should manipulate.

## EXAMPLES

### EXAMPLE 1

Get-JiraConfigServer


Returns the server URL of the JIRA server configured for the JiraPS module.

## PARAMETERS

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.String

{{ Fill in the Description }}

## NOTES

Support for multiple configuration files is limited at this point in time, but enhancements are planned for a future update.

<https://github.com/AtlassianPS/JiraPS/issues/45>
<https://github.com/AtlassianPS/JiraPS/issues/194>


## RELATED LINKS

- [Online Version](https://atlassianps.org/docs/JiraPS/commands/Get-JiraConfigServer/)
- [about_JiraPS_Authentication](../../about/authentication.html)
