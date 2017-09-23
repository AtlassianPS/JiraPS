---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Set-JiraIssueLabel

## SYNOPSIS
Modifies labels on an existing JIRA issue

## SYNTAX

### ReplaceLabels (Default)
```
Set-JiraIssueLabel [-Issue] <Object[]> -Set <String[]> [-Credential <PSCredential>] [-PassThru] [-WhatIf]
 [-Confirm]
```

### ModifyLabels
```
Set-JiraIssueLabel [-Issue] <Object[]> [-Add <String[]>] [-Remove <String[]>] [-Credential <PSCredential>]
 [-PassThru] [-WhatIf] [-Confirm]
```

### ClearLabels
```
Set-JiraIssueLabel [-Issue] <Object[]> [-Clear] [-Credential <PSCredential>] [-PassThru] [-WhatIf] [-Confirm]
```

## DESCRIPTION
This function modifies labels on an existing JIRA issue. 
There are
four supported operations on labels:

* Add: appends additional labels to the labels that an issue already has
* Remove: Removes labels from an issue's current labels
* Set: erases the existing labels on the issue and replaces them with
the provided values
* Clear: removes all labels from the issue

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Set-JiraIssueLabel -Issue TEST-01 -Set 'fixed'
```

This example replaces all existing labels on issue TEST-01 with one
label, "fixed".

### -------------------------- EXAMPLE 2 --------------------------
```
= -7d AND reporter in (joeSmith)' | Set-JiraIssueLabel -Add 'enhancement'
```

This example adds the "enhancement" label to all issues matching the JQL - in this case,
all issues created by user joeSmith in the last 7 days.

### -------------------------- EXAMPLE 3 --------------------------
```
Get-JiraIssue TEST-01 | Set-JiraIssueLabel -Clear
```

This example removes all labels from the issue TEST-01.

## PARAMETERS

### -Issue
Issue key or JiraPS.Issue object returned from Get-JiraIssue

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases: Key

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Set
List of labels that will be set to the issue.
Any label that was already assigned to the issue will be removed.

```yaml
Type: String[]
Parameter Sets: ReplaceLabels
Aliases: Label, Replace

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Add
Existing labels to be added.

```yaml
Type: String[]
Parameter Sets: ModifyLabels
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Remove
Existing labels to be removed.

```yaml
Type: String[]
Parameter Sets: ModifyLabels
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Clear
Remove all labels.

```yaml
Type: SwitchParameter
Parameter Sets: ClearLabels
Aliases: 

Required: False
Position: Named
Default value: False
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
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Whether output should be provided after invoking this function.

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

## INPUTS

### [JiraPS.Issue[]] The JIRA issue that should be modified

## OUTPUTS

### If the -PassThru parameter is provided, this function will provide a reference
to the JIRA issue modified.  Otherwise, this function does not provide output.

## NOTES

## RELATED LINKS

