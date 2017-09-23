---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Remove-JiraRemoteLink

## SYNOPSIS
Removes a remote link from a JIRA issue

## SYNTAX

```
Remove-JiraRemoteLink [-Issue] <Object[]> -LinkId <Int32[]> [-Credential <PSCredential>] [-Force] [-WhatIf]
 [-Confirm]
```

## DESCRIPTION
This function removes a remote link from a JIRA issue.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Remove-JiraRemoteLink Project1-1001 10000,20000
```

Removes two remote link from issue "Project1-1001"

### -------------------------- EXAMPLE 2 --------------------------
```
Get-JiraIssue -Query "project = Project1" | Remove-JiraRemoteLink 10000
```

Removes a specific remote link from all issues in project "Project1"

## PARAMETERS

### -Issue
Issue from which to delete a remote link.

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

### -LinkId
Id of the remote link to delete.

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases: 

Required: True
Position: Named
Default value: None
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

## INPUTS

### [JiraPS.Issue[]] The JIRA issue from which to delete a link

## OUTPUTS

### This function returns no output.

## NOTES

## RELATED LINKS

