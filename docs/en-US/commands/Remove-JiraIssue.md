---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraIssue/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Remove-JiraIssue/
---

# Remove-JiraIssue

## SYNOPSIS

Removes an existing issue from JIRA.

## SYNTAX

### ByInputObject (Default)

```powershell
Remove-JiraIssue [-InputObject] <Object[]> [-IncludeSubTasks] [[-Session] <PSObject>] [-Force] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### ByIssueId 

```powershell
Remove-JiraIssue [-IssueId] <String[]> [-IncludeSubTasks] [[-Session] <PSObject>] [-Force] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function will remove an issue from Jira.
Deleting an issue removes it permanently from JIRA, including all of its comments and attachments.

If you have completed an issue, it should usually be resolved or closed - not deleted.

If an issue includes sub-tasks, these are deleted as well.

## EXAMPLES

### EXAMPLE 1

```powershell
Remove-JiraIssue -IssueId ABC-123
```

Removes issue \[ABC-123\] from JIRA.

### EXAMPLE 2

```powershell
Remove-JiraIssue -IssueId ABC-124 -IncludeSubTasks
```

Removes issue \[ABC-124\] from JIRA, including any subtasks therein.

### EXAMPLE 3

```powershell
Get-JiraIssue -Query "Project = ABC AND label = NeedsDeletion" | Remove-JiraIssue -IncludeSubTasks
```

Removes all issues from project ABC (including their subtasks) that have the label "NeedsDeletion".

## PARAMETERS

### -InputObject

One or more issues to delete, specified as `JiraPS.Issue` objects (e.g. from `Get-JiraIssue`)

```yaml
Type: Object[]
Parameter Sets: ByInputObject
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -IssueId

One or more issues to delete, either:

* Issue Keys (e.g. "TEST-1234")
* Numerical issue IDs

```yaml
Type: String[]
Parameter Sets: ByInputObject
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -IncludeSubTasks

Removes any subtasks associated with the issue(s) to be deleted.

If the issue has no subtasks, this parameter is ignored. If the issue has subtasks and this parameter is missing, then the issue will not be deleted and an error will be returned.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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

### -Force

Suppress user confirmation.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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

### [JiraPS.Issue] / [String]

## OUTPUTS

### Output (if any)

## NOTES

If the issue has subtasks you must include the parameter IncludeSubTasks to delete the issue. You cannot delete an issue without its subtasks also being deleted.

This function requires either the `-Session` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS
