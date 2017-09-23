---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Get-JiraProject

## SYNOPSIS
Returns a project from Jira

## SYNTAX

```
Get-JiraProject [[-Project] <String[]>] [-Credential <PSCredential>]
```

## DESCRIPTION
This function returns information regarding a specified project from Jira.
If
the Project parameter is not supplied, it will return information about all
projects the given user is authorized to view.

The -Project parameter will accept either a project ID or a project key.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-JiraProject -Project TEST -Credential $cred
```

Returns information about the project TEST

### -------------------------- EXAMPLE 2 --------------------------
```
Get-JiraProject 2 -Credential $cred
```

Returns information about the project with ID 2

### -------------------------- EXAMPLE 3 --------------------------
```
Get-JiraProject -Credential $cred
```

Returns information about all projects the user is authorized to view

## PARAMETERS

### -Project
The Project ID or project key of a project to search.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: 

Required: False
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

### [String[]] Project ID or project key
[PSCredential] Credentials to use to connect to Jira

## OUTPUTS

### [JiraPS.Project]

## NOTES

## RELATED LINKS

