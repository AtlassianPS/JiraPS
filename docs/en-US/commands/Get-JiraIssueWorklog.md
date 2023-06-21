---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueWorklog/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueWorklog/
---
# Get-JiraIssueWorklog

## SYNOPSIS

Returns worklogs from an issue in JIRA.
****

## SYNTAX

```powershell
Get-JiraIssueWorklog [-Issue] <Object> [[-Credential] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

This function obtains worklogs from existing issues in JIRA.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraIssueWorklog -Key TEST-001
```

This example returns all worklogs from issue TEST-001.

### EXAMPLE 2

```powershell
Get-JiraIssue TEST-002 | Get-JiraIssueWorklog
```

This example illustrates use of the pipeline to return all worklogs from issue TEST-002.

## PARAMETERS

### -Issue

JIRA issue to check for worklogs.

Can be a `JiraPS.Issue` object, issue key, or internal issue ID.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: Key

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Credential

Credentials to use to connect to JIRA.  
If not specified, this function will use anonymous access.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

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

### [JiraPS.Issue] / [String]

## OUTPUTS

### [JiraPS.WorklogItem]

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Add-JiraIssueWorklog](../Add-JiraIssueWorklog/)

[Get-JiraIssue](../Get-JiraIssue/)
