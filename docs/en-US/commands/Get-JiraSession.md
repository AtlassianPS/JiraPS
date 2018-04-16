---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraSession/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraSession/
---
# Get-JiraSession

## SYNOPSIS

Obtains a reference to the currently saved JIRA session

## SYNTAX

```powershell
Get-JiraSession [<CommonParameters>]
```

## DESCRIPTION

This function obtains a reference to the currently saved JIRA session.

This can provide a JIRA session ID, as well as the username used to connect to JIRA.

## EXAMPLES

### EXAMPLE 1

```powershell
New-JiraSession -Credential (Get-Credential jiraUsername)
Get-JiraSession
```

Description  
 -----------  
Creates a Jira session for jiraUsername, then obtains a reference to it.

## PARAMETERS

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [JiraPS.Session]

## NOTES

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[New-JiraSession](../New-JiraSession/)
