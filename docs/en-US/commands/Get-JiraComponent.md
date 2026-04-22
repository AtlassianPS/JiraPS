---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraComponent/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraComponent/
---
# Get-JiraComponent

## SYNOPSIS

Returns a Component from Jira

## SYNTAX

### ByID (Default)

```powershell
Get-JiraComponent [-ComponentId] <int[]> [-Credential <pscredential>] [<CommonParameters>]
```

### ByProject

```powershell
Get-JiraComponent [-Project] <Object[]> [-Credential <pscredential>] [<CommonParameters>]
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

Returns information about the component with ID 10000

### EXAMPLE 2

```powershell
Get-JiraComponent 20000 -Credential $cred
```

Returns information about the component with ID 20000

### EXAMPLE 3

```powershell
Get-JiraProject "Project1" | Get-JiraComponent
```

Returns information about all components within project 'Project1'

### EXAMPLE 4

```powershell
Get-JiraComponent ABC,DEF
```

Return information about all components within projects 'ABC' and 'DEF'

## PARAMETERS

### -ComponentId

The ID of the component.

```yaml
Type: Int32[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
ParameterSets:
- Name: ByID
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Credential

Credentials to use to connect to JIRA.
If not specified, this function will use anonymous access.

```yaml
Type: PSCredential
DefaultValue: '[System.Management.Automation.PSCredential]::Empty'
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Project

The ID or Key of the Project to search.

```yaml
Type: Object[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByProject
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### String[]

Retrieve all Components in a specific project.

### JiraPS.Component[]

Pipe an existing Component object back into the cmdlet.

### Int[]

Retrieve specific Components by theirs id.

## OUTPUTS

### JiraPS.Component

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

Remaining operations for `component` have not yet been implemented in the module.

## RELATED LINKS
