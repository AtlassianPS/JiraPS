---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Get-JiraComponent

## SYNOPSIS
Returns a Component from Jira

## SYNTAX

### ByID (Default)
```
Get-JiraComponent [-ComponentId] <Int32[]> [-Credential <PSCredential>]
```

### ByProject
```
Get-JiraComponent -Project <Object> [-Credential <PSCredential>]
```

## DESCRIPTION
This function returns information regarding a specified component from Jira.
If -InputObject is given via parameter or pipe all components for
the given project are returned.
It is not possible to get all components with this function.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-JiraComponent -Id 10000 -Credential $cred
```

Returns information about the component with ID 10000

### -------------------------- EXAMPLE 2 --------------------------
```
Get-JiraComponent 20000 -Credential $cred
```

Returns information about the component with ID 20000

### -------------------------- EXAMPLE 3 --------------------------
```
Get-JiraProject Project1 | Get-JiraComponent -Credential $cred
```

Returns information about all components within project 'Project1'

### -------------------------- EXAMPLE 4 --------------------------
```
Get-JiraComponent ABC,DEF
```

Return information about all components within projects 'ABC' and 'DEF'

## PARAMETERS

### -Project
The Project ID or project key of a project to search.

```yaml
Type: Object
Parameter Sets: ByProject
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ComponentId
The Component ID.

```yaml
Type: Int32[]
Parameter Sets: ByID
Aliases: Id

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

## INPUTS

### [String[]] Component ID
[PSCredential] Credentials to use to connect to Jira

## OUTPUTS

### [JiraPS.Component]

## NOTES

## RELATED LINKS

