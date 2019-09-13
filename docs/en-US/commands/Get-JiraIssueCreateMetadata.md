---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueCreateMetadata/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueCreateMetadata/
---
# Get-JiraIssueCreateMetadata

## SYNOPSIS

Returns metadata required to create an issue in JIRA

## SYNTAX

```powershell
Get-JiraIssueCreateMetadata [-Project] <String> [-IssueType] <String> [[-Session] <PSObject>]
 [<CommonParameters>]
```

## DESCRIPTION

This function returns metadata required to create an issue in JIRA - the fields that can be defined in the process of creating an issue.
This can be used to identify custom fields in order to pass them to `New-JiraIssue`.

This function is particularly useful when your JIRA instance includes custom fields that are marked as mandatory.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraIssueCreateMetadata -Project 'TEST' -IssueType 'Bug'
```

This example returns the fields available when creating an issue of type Bug under project TEST.

### EXAMPLE 2

```powershell
Get-JiraIssueCreateMetadata -Project 'JIRA' -IssueType 'Bug' | ? {$_.Required -eq $true}
```

This example returns fields available when creating an issue of type Bug under the project Jira.

It then uses `Where-Object` (aliased by the question mark) to filter only the fields that are required.

## PARAMETERS

### -Project

Project ID or key of the reference issue.

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

### -IssueType

Issue type ID or name.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
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
Position: 3
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

[about_JiraPS_CreatingIssues](../../about/creating-issues.html)

[Get-JiraField](../Get-JiraField/)

[New-JiraIssue](../New-JiraIssue/)
