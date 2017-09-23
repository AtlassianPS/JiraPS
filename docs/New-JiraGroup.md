---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# New-JiraGroup

## SYNOPSIS
Creates a new group in JIRA

## SYNTAX

```
New-JiraGroup [-GroupName] <String> [-Credential <PSCredential>] [-WhatIf] [-Confirm]
```

## DESCRIPTION
This function creates a new group in JIRA.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
New-JiraGroup -GroupName testGroup
```

This example creates a new JIRA group named testGroup.

## PARAMETERS

### -GroupName
Name for the new group.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Name

Required: True
Position: 1
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

### This function does not accept pipeline input.

## OUTPUTS

### [JiraPS.Group] The user object created

## NOTES

## RELATED LINKS

