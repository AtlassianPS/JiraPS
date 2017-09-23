---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Set-JiraVersion

## SYNOPSIS
Modifies an existing Version in JIRA

## SYNTAX

```
Set-JiraVersion [-Version] <Object[]> [-Name <String>] [-Description <String>] [-Archived <Boolean>]
 [-Released <Boolean>] [-ReleaseDate <DateTime>] [-StartDate <DateTime>] [-Project <Object>]
 [-Credential <PSCredential>] [-WhatIf] [-Confirm]
```

## DESCRIPTION
This function modifies the Version for an existing Project in JIRA.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-JiraVersion -Project $Project -Name "Old-Name" | Set-JiraVersion -Name 'New-Name'
```

This example assigns the modifies the existing version with a new name 'New-Name'.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-JiraVersion -ID 162401 | Set-JiraVersion -Description 'Descriptive String'
```

This example assigns the modifies the existing version with a new name 'New-Name'.

## PARAMETERS

### -Version
Version to be changed

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

### -Name
New Name of the Version.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
New Description of the Version.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Archived
New value for Archived.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Released
New value for Released.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReleaseDate
New Date of the release.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartDate
New Date of the user release.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Project
The new Project where this version should be in.
This can be the ID of the Project, or the Project Object

```yaml
Type: Object
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Credentials to use to connect to Jira.

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

### [JiraPS.Version]

## OUTPUTS

### [JiraPS.Version]

## NOTES
This function requires either the -Credential parameter to be passed or a persistent JIRA session.
See New-JiraSession for more details. 
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

