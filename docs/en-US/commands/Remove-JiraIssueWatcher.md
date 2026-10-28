---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraIssueWatcher/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Remove-JiraIssueWatcher/
---
# Remove-JiraIssueWatcher

## SYNOPSIS

Removes a watcher from an existing Jira issue.

## SYNTAX

```powershell
Remove-JiraIssueWatcher [-Watcher] <AtlassianPS.JiraPS.User[]> [-Issue] <AtlassianPS.JiraPS.Issue> [[-Connection] <AtlassianPS.Connection>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function removes a watcher from an existing issue in Jira.

## EXAMPLES

### Example 1

```powershell
Remove-JiraIssueWatcher -Watcher 'fred' -Issue 'TEST-001'
```

This example removes a watcher from the issue TEST-001.

### Example 2

```powershell
Get-JiraIssue 'TEST-002' | Remove-JiraIssueWatcher 'fred'
```

This example illustrates pipeline use from Get-JiraIssue to Remove-JiraIssueWatcher.

### Example 3

```powershell
Get-JiraIssue -Query 'project = "TEST" AND created >= -5d' | Remove-JiraIssueWatcher 'fred'
```

This example illustrates removing watcher on all projects which match a given JQL query.

It would be best to validate the query first to make sure the query returns the expected issues!

## PARAMETERS

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Connection

Active Jira connection for this operation.
When omitted, the command uses the selected Jira default.
Create connections with Connect-Jira; resolve names with Get-JiraConnection -Name.

```yaml
Type: AtlassianPS.Connection
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Issue

Issue keys, numeric ID strings or typed issue objects.

```yaml
Type: AtlassianPS.JiraPS.Issue
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Key
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Watcher

Exact user identifiers or typed user objects.
Cloud uses accountId; Data Center uses username.
Display names are not identifiers.

```yaml
Type: AtlassianPS.JiraPS.User[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
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

### AtlassianPS.JiraPS.Issue

## OUTPUTS

None.

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Add-JiraIssueWatcher](../Add-JiraIssueWatcher/)

[Get-JiraIssue](../Get-JiraIssue/)

[Get-JiraUser](../Get-JiraUser/)

[Get-JiraIssueWatcher](../Get-JiraIssueWatcher/)
