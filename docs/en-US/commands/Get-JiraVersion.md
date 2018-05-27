---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraVersion/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraVersion/
---
# Get-JiraVersion

## SYNOPSIS

This function returns information about a JIRA Project's Version

## SYNTAX

### byId (Default)

```powershell
Get-JiraVersion -Id <Int32[]> [-Credential <PSCredential>] [<CommonParameters>]
```

### byInputVersion

```powershell
Get-JiraVersion [-InputVersion] <Object> [-Credential <PSCredential>] [<CommonParameters>]
```

### byProject

```powershell
Get-JiraVersion [-Project] <String[]> [-Name <String[]>] [-Credential <PSCredential>] [<CommonParameters>]
```

### byInputProject

```powershell
Get-JiraVersion [-InputProject] <Object> [-Name <String[]>] [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

This function provides information about JIRA Version

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraVersion -Project $ProjectKey
```

This example returns information about all JIRA Version visible to the current user for the project.

### EXAMPLE 2

```powershell
Get-JiraVersion -Project $ProjectKey -Name '1.0.0.0'
```

This example returns the information of a specific Version.

### EXAMPLE 3

```powershell
Get-JiraProject "FOO", "BAR" | Get-JiraVersion -Name "v1.0", "v2.0"
```

Get the Version with name "v1.0" and "v2.0" from both projects "FOO" and "BAR"

### EXAMPLE 4

```powershell
Get-JiraVersion -ID '66596'
```

This example returns information about all JIRA Version visible to the current user
(or using anonymous access if a JiraPS session has not been defined) for the project.

## PARAMETERS

### -Id

The Version ID

```yaml
Type: Int32[]
Parameter Sets: byId
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputVersion

A Version object to search for

```yaml
Type: JiraPS.Version
Parameter Sets: byInputVersion
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Project

Project key of a project to search

```yaml
Type: String[]
Parameter Sets: byProject
Aliases: Key

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputProject

A Project Object to search

```yaml
Type: JiraPS.Project
Parameter Sets: byInputProject
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name

Jira Version Name

```yaml
Type: String[]
Parameter Sets: byProject, byInputProject
Aliases: Versions

Required: False
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [JiraPS.Version]

### [JiraPS.Project]

## OUTPUTS

### [JiraPS.Version]

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraProject](../Get-JiraProject/)

[New-JiraVersion](../New-JiraVersion/)

[Remove-JiraVersion](../Remove-JiraVersion/)

[Set-JiraVersion](../Set-JiraVersion/)
