---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraIssue/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Remove-JiraIssue/
---
# Remove-JiraIssue

## SYNOPSIS

Removes an existing issue from Jira.

## SYNTAX

```powershell
Remove-JiraIssue [-Issue] <AtlassianPS.JiraPS.Issue[]> [-IncludeSubTasks] [-Connection <AtlassianPS.Connection>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function will remove an issue from Jira.
Deleting an issue removes it permanently from Jira, including all of its comments and attachments.

If you have completed an issue, it should usually be resolved or closed - not deleted.

If an issue includes sub-tasks, these are deleted as well.

## EXAMPLES

### Example 1

```powershell
Remove-JiraIssue -IssueId ABC-123
```

Removes issue \[ABC-123\] from Jira.

### Example 2

```powershell
Remove-JiraIssue -IssueId ABC-124 -IncludeSubTasks
```

Removes issue \[ABC-124\] from Jira, including any subtasks therein.

### Example 3

```powershell
Get-JiraIssue -Query 'Project = ABC AND label = NeedsDeletion' | Remove-JiraIssue -IncludeSubTasks
```

Removes all issues from project ABC (including their subtasks) that have the label "NeedsDeletion".

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
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IncludeSubTasks

Removes any subtasks associated with the issue(s) to be deleted.

If the issue has no subtasks, this parameter is ignored.
If the issue has subtasks and this parameter is missing, then the issue will not be deleted and an error will be returned.

```yaml
Type: SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases:
- deleteSubtasks
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

### -Issue

Issue keys, numeric ID strings or typed issue objects.

```yaml
Type: AtlassianPS.JiraPS.Issue[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Key
- Id
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
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

### AtlassianPS.JiraPS.Issue[]

## OUTPUTS

### Output (if any)

## NOTES

If the issue has subtasks you must include the parameter IncludeSubTasks to delete the issue.
You cannot delete an issue without its subtasks also being deleted.

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)
