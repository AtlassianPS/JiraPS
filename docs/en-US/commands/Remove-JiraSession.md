---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraSession/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Remove-JiraSession/
---
# Remove-JiraSession

## SYNOPSIS

[DEPRECATED] Removes a persistent JIRA authenticated session

## SYNTAX

```powershell
Remove-JiraSession [[-Session] <Object>] [<CommonParameters>]
```

## DESCRIPTION

> This command has currently no functionality

This function removes a persistent JIRA authenticated session and closes the session for JIRA.
This can be used to "log out" of JIRA once work is complete.

If called with the Session parameter, this function will attempt to close the provided `JiraPS.Session` object.

If called with no parameters, this function will close the saved JIRA session in the module's PrivateData.

## EXAMPLES

### EXAMPLE 1

```powershell
New-JiraSession -Credential (Get-Credential jiraUsername)
Get-JiraIssue TEST-01
Remove-JiraSession
```

This example creates a JIRA session for jiraUsername, runs Get-JiraIssue, and closes the JIRA session.

### EXAMPLE 2

```powershell
$s = New-JiraSession -Credential (Get-Credential jiraUsername)
Remove-JiraSession $s
```

This example creates a JIRA session and saves it to a variable, then uses the variable reference to
close the session.

## PARAMETERS

### -Session

A Jira session to be closed.

If not specified, this function will use a saved session.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [JiraPS.Session]

## OUTPUTS

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraSession](../Get-JiraSession/)

[New-JiraSession](../New-JiraSession/)
