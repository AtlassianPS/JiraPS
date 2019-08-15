---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/New-JiraSession/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/New-JiraSession/
---
# New-JiraSession

## SYNOPSIS

Creates a persistent JIRA authenticated session which can be used by other JiraPS functions

## SYNTAX

```powershell
New-JiraSession [-Credential] <PSCredential> [[-ConfigFile] <String>] [[-Headers] <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION

This function creates a persistent,
authenticated session in to JIRA which can be used by all other
JiraPS functions instead of explicitly passing parameters.

This removes the need to use the `-Credential` parameter constantly for each function call.

Moreover you may define default configuration file for the session.

You can find more information in [about_JiraPS_Authentication](../../about/authentication.html)

## EXAMPLES

### EXAMPLE 1

```powershell
New-JiraSession -Credential (Get-Credential jiraUsername)
Get-JiraIssue TEST-01
```

Creates a Jira session for jiraUsername.
The following `Get-JiraIssue` is run using the saved session for jiraUsername.

## PARAMETERS

### -Credential

Credentials to use to connect to JIRA.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Headers

Additional Headers

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: @{}
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [PSCredential]

## OUTPUTS

### [JiraPS.Session]

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraSession](../Get-JiraSession/)
