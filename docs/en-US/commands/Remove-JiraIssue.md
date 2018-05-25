---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version:
schema: 2.0.0
---

# Remove-JiraIssue

## SYNOPSIS

Removes an existing issue from JIRA.

## SYNTAX

```powershell
Remove-JiraIssue [-Issue] <Object[]> [-IncludeSubTasks] [[-Credential] <PSCredential>] [-Force] [-WhatIf]
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
Remove-JiraUser -Issue ABC-123
```

Removes issue \[ABC-123\] from JIRA.

### EXAMPLE 2

```powershell
Remove-JiraUser -Issue ABC-124 -IncludeSubTasks
```

Removes issue \[ABC-124\] from JIRA, including any subtasks therein.

### EXAMPLE 3

```powershell
Get-JiraIssue -Query "Project = ABC AND label = NeedsDeletion" | Remove-JiraUser -IncludeSubTasks
```

Removes all issues from project ABC (including their subtasks) that have the label "NeedsDeletion".

## PARAMETERS

### -Issue

One or more issues to delete. These can be specified as:

* Issue key(s) (e.g. `[ABC-123]`)
* Numerical ID(s)
* Object(s) to delete (such as ones returned from `Get-JiraIssue`)

```yaml
Type: Object[]
Parameter Sets: (All)
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

### -Credential

Credentials to use to connect to JIRA.  

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

This function requires either the \`-Credential\` parameter to be passed or a persistent JIRA session.
See \`New-JiraSession\` for more details.

## RELATED LINKS
