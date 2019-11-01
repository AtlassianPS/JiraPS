---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraProject/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraProject/
---
# Get-JiraProject

## SYNOPSIS

Returns a project from Jira

## SYNTAX

### _All (Default)

```powershell
Get-JiraProject [-Session <PSObject>] [<CommonParameters>]
```

### _Search

```powershell
Get-JiraProject [-Project] <String[]> [-Session <PSObject>] [<CommonParameters>]
```

## DESCRIPTION

This function returns information regarding a specified project from Jira.

If the Project parameter is not supplied,
it will return information about all projects the given user is authorized to view.

The `-Project` parameter will accept either a project ID or a project key.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraProject -Project TEST -Session $session
```

Returns information about the project TEST

### EXAMPLE 2

```powershell
Get-JiraProject 2 -Session $session
```

Returns information about the project with ID 2

### EXAMPLE 3

```powershell
Get-JiraProject
```

Returns information about all projects the user is authorized to view

## PARAMETERS

### -Project

The Project ID or project key of a project to search.

```yaml
Type: String[]
Parameter Sets: _Search
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Session

Session to use to connect to JIRA.  
If not specified, this function will use default session.
The name of a session, PSCredential object or session's instance itself is accepted to pass as value for the parameter.

```yaml
Type: psobject
Parameter Sets: (All)
Aliases: Credential

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

## OUTPUTS

### [JiraPS.Project]

## NOTES

This function requires either the `-Session` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

Remaining operations for `project` have not yet been implemented in the module.

## RELATED LINKS
