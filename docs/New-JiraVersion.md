---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# New-JiraVersion

## SYNOPSIS
Creates a new FixVersion in JIRA

## SYNTAX

### byObject (Default)
```
New-JiraVersion [-InputObject] <Object> [-Credential <PSCredential>] [-WhatIf] [-Confirm]
```

### byParameters
```
New-JiraVersion [-Name] <String> [-Description <String>] [-Archived <Boolean>] [-Released <Boolean>]
 [-ReleaseDate <DateTime>] [-StartDate <DateTime>] -Project <Object> [-Credential <PSCredential>] [-WhatIf]
 [-Confirm]
```

## DESCRIPTION
This function creates a new FixVersion in JIRA.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
New-JiraVersion -Name '1.0.0.0' -Project "RD"
```

Description
-----------
This example creates a new JIRA Version named '1.0.0.0' in project \`RD\`.

### -------------------------- EXAMPLE 2 --------------------------
```
$project = Get-JiraProject -Project "RD"
```

New-JiraVersion -Name '1.0.0.0' -Project $project -ReleaseDate "2000-12-31"
Description
-----------
Create a new Version in Project \`RD\` with a set release date.

### -------------------------- EXAMPLE 3 --------------------------
```
$version = Get-JiraVersion -Name "1.0.0.0" -Project "RD"
```

$version = $version.Project.Key "TEST"
$version | New-JiraVersion
Description
-----------
This example duplicates the Version named '1.0.0.0' in Project \`RD\` to Project \`TEST\`.

## PARAMETERS

### -InputObject
Version object that should be created on the server.

```yaml
Type: Object
Parameter Sets: byObject
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name
Name of the version to create.

```yaml
Type: String
Parameter Sets: byParameters
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
Description of the version.

```yaml
Type: String
Parameter Sets: byParameters
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Archived
Create the version as archived.

```yaml
Type: Boolean
Parameter Sets: byParameters
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Released
Create the version as released.

```yaml
Type: Boolean
Parameter Sets: byParameters
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReleaseDate
Date of the release.

```yaml
Type: DateTime
Parameter Sets: byParameters
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartDate
Date of the release.

```yaml
Type: DateTime
Parameter Sets: byParameters
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Project
The Project ID

```yaml
Type: Object
Parameter Sets: byParameters
Aliases: 

Required: True
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

## OUTPUTS

### [JiraPS.Version]

## NOTES
This function requires either the -Credential parameter to be passed or a persistent JIRA session.
See New-JiraSession for more details. 
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraVersion]()

[Remove-JiraVersion]()

[Set-JiraVersion]()

[Get-JiraProject]()

