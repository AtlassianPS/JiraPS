---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraIssueWatcher/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Remove-JiraIssueWatcher/
---
# Remove-JiraIssueWatcher

## SYNOPSIS

Removes a watcher from an existing JIRA issue

## SYNTAX

```powershell
Remove-JiraIssueWatcher [-Watcher] <String[]> [-Issue] <Object> [[-Credential] <PSCredential>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function removes a watcher from an existing issue in JIRA.

## EXAMPLES

### EXAMPLE 1

```powershell
Remove-JiraIssueWatcher -Watcher "fred" -Issue "TEST-001"
```

This example removes a watcher from the issue TEST-001.

### EXAMPLE 2

```powershell
Get-JiraIssue "TEST-002" | Remove-JiraIssueWatcher "fred"
```

This example illustrates pipeline use from Get-JiraIssue to Remove-JiraIssueWatcher.

### EXAMPLE 3

```powershell
Get-JiraIssue -Query 'project = "TEST" AND created >= -5d' | Remove-JiraIssueWatcher "fred"
```

This example illustrates removing watcher on all projects which match a given JQL query.

It would be best to validate the query first to make sure the query returns the expected issues!

## PARAMETERS

### -Watcher

Watcher that should be removed from JIRA

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Issue

Issue that should be updated.

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

### -Credential

Credentials to use to connect to JIRA.  
If not specified, this function will use anonymous access.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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

### [JiraPS.Issue]

## OUTPUTS

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Add-JiraIssueWatcher](../Add-JiraIssueWatcher/)

[Get-JiraIssue](../Get-JiraIssue/)

[Get-JiraUser](../Get-JiraUser/)

[Get-JiraIssueWatcher](../Get-JiraIssueWatcher/)
