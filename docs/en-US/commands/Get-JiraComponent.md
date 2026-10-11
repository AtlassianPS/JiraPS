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

Returns a component from Jira.

## SYNTAX

### ByID (Default)

```powershell
Get-JiraComponent [-ComponentId] <int[]> [-Credential <pscredential>] [<CommonParameters>]
```

### ByProject

```powershell
Get-JiraComponent [-Project] <AtlassianPS.JiraPS.Project[]> [-Credential <pscredential>] [<CommonParameters>]
```

## DESCRIPTION

This function returns information regarding a specified component from Jira.

Components are specific to a project.
Therefore, it is not possible to query for components without a project.

## EXAMPLES

### Example 1

```powershell
Get-JiraComponent -Id 10000
```

Returns information about the component with ID 10000

### Example 2

```powershell
Get-JiraComponent 20000 -Credential $cred
```

Returns information about the component with ID 20000

### Example 3

```powershell
Get-JiraProject 'Project1' | Get-JiraComponent
```

Returns information about all components within project 'Project1'

### Example 4

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

Credentials to use to connect to Jira.
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

The ID or key of the project to search.

```yaml
Type: AtlassianPS.JiraPS.Project[]
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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable.
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.Project

Pipe a project object to retrieve its components.

### System.String

Pipe a project key or numeric project ID to retrieve its components.

### System.Int64

Pipe a numeric project ID to retrieve its components.

## OUTPUTS

### AtlassianPS.JiraPS.Component

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent Jira session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to Jira.

Remaining operations for `component` have not yet been implemented in the module.

## RELATED LINKS
