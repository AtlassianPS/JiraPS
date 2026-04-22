---
document type: cmdlet
external help file: JiraPS-help.xml
HelpUri: https://atlassianps.org/docs/JiraPS/commands/Set-JiraConfigServer/
Locale: en-DE
Module Name: JiraPS
ms.date: 04.22.2026
PlatyPS schema version: 2024-05-01
title: Set-JiraConfigServer
---

# Set-JiraConfigServer

## SYNOPSIS

Defines the configured URL for the JIRA server

## SYNTAX

### __AllParameterSets

```
Set-JiraConfigServer [-Server] <uri> [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function defines the configured URL for the JIRA server that JiraPS should manipulate.

## EXAMPLES

### EXAMPLE 1

Set-JiraConfigServer 'https://jira.example.com:8080'


This example defines the server URL of the JIRA server configured for the JiraPS module.

## PARAMETERS

### -Server

The base URL of the Jira instance.

```yaml
Type: System.Uri
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Uri
ParameterSets:
- Name: (All)
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

### String

{{ Fill in the Description }}

## OUTPUTS

### System.String

{{ Fill in the Description }}

## NOTES

Support for multiple configuration files is limited at this point in time,
but enhancements are planned for the next major release.
This can be tracked in [JiraPS#194](https://github.com/AtlassianPS/JiraPS/issues/194)


## RELATED LINKS

- [Online Version](https://atlassianps.org/docs/JiraPS/commands/Set-JiraConfigServer/)
- [about_JiraPS_Authentication](../../about/authentication/)
- [Get-JiraConfigServer](../Get-JiraConfigServer/)
