---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueEditMetadata/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueEditMetadata/
---
# Get-JiraIssueEditMetadata

## SYNOPSIS

Returns metadata required to change an issue in JIRA

## SYNTAX

```powershell
Get-JiraIssueEditMetadata [-Issue] <String> [[-Session] <PSObject>] [<CommonParameters>]
```

## DESCRIPTION

This function returns metadata required to update an issue in JIRA - the fields that can be defined in the process of updating an issue.
This can be used to identify custom fields in order to pass them to `Set-JiraIssue`.

This function is particularly useful when your JIRA instance includes custom fields that are marked as mandatory.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraIssueEditMetadata -Issue "TEST-001"
```

This example returns the fields available when updating the issue "TEST-001".

### EXAMPLE 2

```powershell
Get-JiraIssueEditMetadata -Issue "TEST-001" | ? {$_.Required -eq $true}
```

This example returns fields available when updating the issue "TEST-001".
It then uses `Where-Object` (aliased by the question mark) to filter only the fields that are required.

## PARAMETERS

### -Issue

Issue id or key of the reference issue.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Session

Session to use to connect to JIRA.  
If not specified, this function will use default session.
The name of a session, PSCredential object or session's instance itself is accepted to pass as value for the parameter.

```yaml
Type: psobject
Parameter Sets: (All)
Aliases: Credential

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [JiraPS.Field]

## NOTES

This function requires either the `-Session` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[about_JiraPS_UpdatingIssues](../../about/updating-issues.html)

[Get-JiraField](../Get-JiraField/)

[Set-JiraIssue](../Set-JiraIssue/)
