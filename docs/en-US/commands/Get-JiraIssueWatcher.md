---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueWatcher/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueWatcher/
---
# Get-JiraIssueWatcher

## SYNOPSIS

Returns watchers on an issue in JIRA.

## SYNTAX

```powershell
Get-JiraIssueWatcher [-Issue] <Object> [[-Credential] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

This function obtains watchers from existing issues in JIRA.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraIssueWatcher -Key TEST-001
```

Description  
 -----------  
This example returns all watchers posted to issue TEST-001.

### EXAMPLE 2

```powershell
Get-JiraIssue TEST-002 | Get-JiraIssueWatcher
```

Description  
 -----------  
This example illustrates use of the pipeline to return all watchers on issue TEST-002.

## PARAMETERS

### -Issue

JIRA issue to check for watchers.

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

### <TODO> : This function outputs all JiraPS.Watchers issues associated with the provided issue.

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Add-JiraIssueWatcher](../Add-JiraIssueWatcher/)

[Remove-JiraIssueWatcher](../Remove-JiraIssueWatcher/)
