---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Remove-JiraIssueLink

## SYNOPSIS
Removes a issue link from a JIRA issue

## SYNTAX

```
Remove-JiraIssueLink [-IssueLink] <Object[]> [-Credential <PSCredential>] [-WhatIf] [-Confirm]
```

## DESCRIPTION
This function removes a issue link from a JIRA issue.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Remove-JiraIssueLink 1234,2345
```

Removes two issue links with id 1234 and 2345

### -------------------------- EXAMPLE 2 --------------------------
```
Get-JiraIssue -Query "project = Project1 AND label = lingering" | Remove-JiraIssueLink
```

Removes all issue links for all issues in project Project1 and that have a label "lingering"

## PARAMETERS

### -IssueLink
IssueLink to delete

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

### -Credential
Credentials to use to connect to Jira

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

### [JiraPS.IssueLink[]] The JIRA issue link  which to delete

## OUTPUTS

### This function returns no output.

## NOTES

## RELATED LINKS

