---
document type: cmdlet
external help file: JiraPS-help.xml
HelpUri: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraSession/
Locale: en-DE
Module Name: JiraPS
ms.date: 04.22.2026
PlatyPS schema version: 2024-05-01
title: Remove-JiraSession
---

# Remove-JiraSession

## SYNOPSIS

[DEPRECATED] Removes a persistent JIRA authenticated session

## SYNTAX

### __AllParameterSets

```
Remove-JiraSession [[-Session] <Object>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

> This command has currently no functionality

This function removes a persistent JIRA authenticated session and closes the session for JIRA.
This can be used to "log out" of JIRA once work is complete.

If called with the Session parameter, this function will attempt to close the provided `JiraPS.Session` object.

If called with no parameters, this function will close the saved JIRA session in the module's PrivateData.

## EXAMPLES

### EXAMPLE 1

New-JiraSession -Credential (Get-Credential jiraUsername)
Get-JiraIssue TEST-01
Remove-JiraSession


This example creates a JIRA session for jiraUsername, runs Get-JiraIssue, and closes the JIRA session.

### EXAMPLE 2

$s = New-JiraSession -Credential (Get-Credential jiraUsername)
Remove-JiraSession $s


This example creates a JIRA session and saves it to a variable, then uses the variable reference to
close the session.

## PARAMETERS

### -Session

A Jira session to be closed.

If not specified, this function will use a saved session.

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: false
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

### JiraPS.Session

{{ Fill in the Description }}

### System.Object

{{ Fill in the Description }}

## OUTPUTS

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.


## RELATED LINKS

- [Online Version](https://atlassianps.org/docs/JiraPS/commands/Remove-JiraSession/)
- [Get-JiraSession](../Get-JiraSession/)
- [New-JiraSession](../New-JiraSession/)
