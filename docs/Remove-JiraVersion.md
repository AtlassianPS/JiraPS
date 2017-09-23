---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Remove-JiraVersion

## SYNOPSIS
This function removes an existing version.

## SYNTAX

```
Remove-JiraVersion [-Version] <Object[]> [-Credential <PSCredential>] [-Force] [-WhatIf] [-Confirm]
```

## DESCRIPTION
This function removes an existing version in JIRA.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-JiraVersion -Name '1.0.0.0' -Project $Project | Remove-JiraVersion
```

This example removes the Version given.

### -------------------------- EXAMPLE 2 --------------------------
```
Remove-JiraVersion -Version '66596'
```

This example removes the Version given.

## PARAMETERS

### -Version
Version Object or ID to delete.

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

### [JiraPS.Version]

## OUTPUTS

### This Function outputs no results

## NOTES
This function requires either the -Credential parameter to be passed or a persistent JIRA session.
See New-JiraSession for more details. 
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[New-JiraVersion]()

[Get-JiraVersion]()

[Set-JiraVersion]()

