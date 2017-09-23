---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Get-JiraVersion

## SYNOPSIS
This function returns information about a JIRA Project's Version

## SYNTAX

### byId (Default)
```
Get-JiraVersion -Id <Int32[]> [-Credential <PSCredential>]
```

### byProject
```
Get-JiraVersion [-Project] <String[]> [-Name <String[]>] [-Credential <PSCredential>]
```

## DESCRIPTION
This function provides information about JIRA Version

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-JiraVersion -Project $ProjectKey
```

This example returns information about all JIRA Version visible to the current user for the project.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-JiraVersion -Project $ProjectKey -Name '1.0.0.0'
```

This example returns the information of a specific Version.

### -------------------------- EXAMPLE 3 --------------------------
```
Get-JiraVersion -ID '66596'
```

This example returns information about all JIRA Version visible to the current user (or using anonymous access if a JiraPS session has not been defined) for the project.

## PARAMETERS

### -Project
Project key of a project to search

```yaml
Type: String[]
Parameter Sets: byProject
Aliases: Key

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Name
Jira Version Name

```yaml
Type: String[]
Parameter Sets: byProject
Aliases: Versions

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id
The Version ID

```yaml
Type: Int32[]
Parameter Sets: byId
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
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

## INPUTS

### [JiraPS.Project]

## OUTPUTS

### [JiraPS.Version]

## NOTES
This function requires either the -Credential parameter to be passed or a persistent JIRA session.
See New-JiraSession for more details. 
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[New-JiraVersion]()

[Remove-JiraVersion]()

[Set-JiraVersion]()

[Get-JiraProject]()

