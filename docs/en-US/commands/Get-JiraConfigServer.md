---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraConfigServer/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraConfigServer/
---
# Get-JiraConfigServer

## SYNOPSIS

Obtains the selected Jira API endpoint or configured endpoint.

## SYNTAX

```powershell
Get-JiraConfigServer [<CommonParameters>]
```

## DESCRIPTION

Returns the API endpoint of the current default Jira connection.
When no connection is selected, returns the endpoint saved by Set-JiraConfigServer or the previously configured Jira server URL.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraConfigServer
```

Returns the selected Jira API endpoint, falling back to the configured endpoint when no connection is selected.

## PARAMETERS

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.String

## NOTES

Use Get-JiraConnection to inspect connections and Connect-Jira to create one.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)
