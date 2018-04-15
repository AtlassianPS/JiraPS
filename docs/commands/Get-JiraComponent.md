---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraComponent/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraComponent/
---
# Get-JiraComponent

## SYNOPSIS

Returns a Component from Jira

## SYNTAX

### ByID (Default)

```powershell
Get-JiraComponent [-ComponentId] <Int32[]> [-Credential <PSCredential>] [<CommonParameters>]
```

### ByProject

```powershell
Get-JiraComponent [-Project] <Object[]> [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

This function returns information regarding a specified component from Jira.

Components are specific to a Project.
Therefore, it is not possible to query for Components without a project.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraComponent -Id 10000
```

Description  
 -----------  
Returns information about the component with ID 10000

### EXAMPLE 2

```powershell
Get-JiraComponent 20000 -Credential $cred
```

Description  
 -----------  
Returns information about the component with ID 20000

### EXAMPLE 3

```powershell
Get-JiraProject "Project1" | Get-JiraComponent
```

Description  
 -----------  
Returns information about all components within project 'Project1'

### EXAMPLE 4

```powershell
Get-JiraComponent ABC,DEF
```

Description  
 -----------  
Return information about all components within projects 'ABC' and 'DEF'

## PARAMETERS

### -Project

The ID or Key of the Project to search.

```yaml
Type: Object[]
Parameter Sets: ByProject
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ComponentId

The ID of the component.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [String[]] / [JiraPS.Component[]]

Retrieve all Components in a specific project.

### [Int[]]

Retrieve specific Components by theirs id.

## OUTPUTS

### [JiraPS.Component]

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

Remaining operations for `component` have not yet been implemented in the module.

## RELATED LINKS
