---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraConfigServer/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraConfigServer/
---

# Get-JiraConfigServer

## SYNOPSIS

Obtains the configured URL for the JIRA server

## SYNTAX

```powershell
Get-JiraConfigServer [[-ConfigFile] <String>] [<CommonParameters>]
```

## DESCRIPTION

This function returns the configured URL for the JIRA server that JiraPS should manipulate.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraConfigServer
```

Returns the server URL of the JIRA server configured for the JiraPS module.

## PARAMETERS

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [System.String]

## NOTES

Support for multiple configuration files is limited at this point in time, but enhancements are planned for a future update.

<https://github.com/AtlassianPS/JiraPS/issues/45>
<https://github.com/AtlassianPS/JiraPS/issues/194>

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)
