---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Add-JiraIssueWorklog/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Add-JiraIssueWorklog/
---
# Add-JiraIssueWorklog

## SYNOPSIS

Adds a worklog item to an existing JIRA issue

## SYNTAX

```powershell
Add-JiraIssueWorklog [-Comment] <String> [-Issue] <Object> [-TimeSpent] <TimeSpan> [-DateStarted] <DateTime>
 [[-VisibleRole] <String>] [[-Credential] <PSCredential>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function adds a worklog item to an existing issue in JIRA.
You can optionally set the visibility of the item (All Users, Developers, or Administrators).

## EXAMPLES

### EXAMPLE 1

```powershell
Add-JiraIssueWorklog -Comment "Test comment" -Issue "TEST-001" -TimeSpent 60 -DateStarted (Get-Date)
```

This example adds a simple worklog item to the issue TEST-001.

### EXAMPLE 2

```powershell
Get-JiraIssue "TEST-002" | Add-JiraIssueWorklog "Test worklog item from PowerShell" -TimeSpent 60 -DateStarted (Get-Date)
```

This example illustrates pipeline use from `Get-JiraIssue` to `Add-JiraIssueWorklog`.

### EXAMPLE 3

```powershell
Get-JiraIssue -Query 'project = "TEST" AND created >= -5d' |
    Add-JiraIssueWorklog "This issue has been cancelled per Vice President's orders." -TimeSpent 60 -DateStarted (Get-Date)
```

This example illustrates logging work on all projects which match a given JQL query.
It would be best to validate the query first to make sure the query returns the expected issues!

### EXAMPLE 4

```powershell
$comment = Get-Process | Format-Jira
Add-JiraIssueWorklog $comment -Issue TEST-003 -TimeSpent 60 -DateStarted (Get-Date)
```

This example illustrates adding a comment based on other logic to a JIRA issue.

Note the use of `Format-Jira` to convert the output of `Get-Process` into a format that is easily read by users.

## PARAMETERS

### -Comment

Worklog item that should be added to JIRA

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

### -Issue

Issue to receive the new worklog item.

Can be a `JiraPS.Issue` object, issue key, or internal issue ID.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: Key

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -TimeSpent

Time spent to be logged

```yaml
Type: TimeSpan
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -DateStarted

Date/time started to be logged

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -VisibleRole

Visibility of the comment.  
Defines if the comment should be publicly visible, viewable to only developers, or only administrators.

Allowed values are:

- `All Users`
- `Developers`
- `Administrators`

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: All Users
Accept pipeline input: False
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
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### This function can accept JiraPS.Issue objects via pipeline.

## OUTPUTS

### [JiraPS.Worklogitem]

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraIssueWorklog](../Get-JiraIssueWorklog)

[Get-JiraIssue](../Get-JiraIssue/)

[Format-Jira](../Format-Jira/)
