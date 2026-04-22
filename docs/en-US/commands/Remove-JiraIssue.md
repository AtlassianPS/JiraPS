---
document type: cmdlet
external help file: JiraPS-help.xml
HelpUri: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraIssue/
Locale: en-DE
Module Name: JiraPS
ms.date: 04.22.2026
PlatyPS schema version: 2024-05-01
title: Remove-JiraIssue
---

# Remove-JiraIssue

## SYNOPSIS

Removes an existing issue from JIRA.

## SYNTAX

### ByInputObject (Default)

```
Remove-JiraIssue [-InputObject] <Issue[]> [-IncludeSubTasks] [-Credential <pscredential>] [-Force]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ByIssueId

```
Remove-JiraIssue [-IssueId] <string[]> [-IncludeSubTasks] [-Credential <pscredential>] [-Force]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function will remove an issue from Jira.
Deleting an issue removes it permanently from JIRA, including all of its comments and attachments.

If you have completed an issue, it should usually be resolved or closed - not deleted.

If an issue includes sub-tasks, these are deleted as well.

## EXAMPLES

### EXAMPLE 1

Remove-JiraIssue -IssueId ABC-123


Removes issue \[ABC-123\] from JIRA.

### EXAMPLE 2

Remove-JiraIssue -IssueId ABC-124 -IncludeSubTasks


Removes issue \[ABC-124\] from JIRA, including any subtasks therein.

### EXAMPLE 3

Get-JiraIssue -Query "Project = ABC AND label = NeedsDeletion" | Remove-JiraIssue -IncludeSubTasks


Removes all issues from project ABC (including their subtasks) that have the label "NeedsDeletion".

## PARAMETERS

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
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

### -Credential

Credentials to use to connect to JIRA.

```yaml
Type: System.Management.Automation.PSCredential
DefaultValue: ''
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

### -Force

Suppress user confirmation.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
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
Type: System.Management.Automation.SwitchParameter
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

### -InputObject

One or more issues to delete, specified as `JiraPS.Issue` objects (e.g.
from `Get-JiraIssue`)

```yaml
Type: System.Object[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Issue
ParameterSets:
- Name: ByInputObject
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IssueId

One or more issues to delete, either:

* Issue Keys (e.g.
"TEST-1234")
* Numerical issue IDs

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
- Key
- issueIdOrKey
ParameterSets:
- Name: ByIssueId
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
Type: System.Management.Automation.SwitchParameter
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

### JiraPS.Issue / String

{{ Fill in the Description }}

### System.Object[]

{{ Fill in the Description }}

## OUTPUTS

### Output (if any)

{{ Fill in the Description }}

## NOTES

If the issue has subtasks you must include the parameter IncludeSubTasks to delete the issue.
You cannot delete an issue without its subtasks also being deleted.

This function requires either the \`-Credential\` parameter to be passed or a persistent JIRA session.
See \`New-JiraSession\` for more details.


## RELATED LINKS

- [Online Version](https://atlassianps.org/docs/JiraPS/commands/Remove-JiraIssue/)
