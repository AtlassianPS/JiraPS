---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Remove-JiraGroup

## SYNOPSIS
Removes an existing group from JIRA

## SYNTAX

```
Remove-JiraGroup [-Group] <Object[]> [-Credential <PSCredential>] [-Force] [-WhatIf] [-Confirm]
```

## DESCRIPTION
This function removes an existing group from JIRA.

Deleting a group does not delete users from JIRA.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Remove-JiraGroup -GroupName testGroup
```

Removes the JIRA group testGroup

## PARAMETERS

### -Group
Group Object or ID to delete.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases: GroupName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
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

### [JiraPS.Group[]] The JIRA groups to delete

## OUTPUTS

### This function returns no output.

## NOTES

## RELATED LINKS

