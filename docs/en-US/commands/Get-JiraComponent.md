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

```
Get-JiraComponent [-ComponentId] <int[]> [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

### ByProject

```
Get-JiraComponent [-Project] <AtlassianPS.JiraPS.Project[]> [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

## ALIASES

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
Get-JiraComponent 20000
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

### -Connection

Active Jira connection for this operation.
When omitted, the command uses the selected Jira default.
Create connections with Connect-Jira; resolve names with Get-JiraConnection -Name.

```yaml
Type: AtlassianPS.Connection
DefaultValue: None
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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.Project[]

## OUTPUTS

### AtlassianPS.JiraPS.Component

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

Remaining operations for `component` have not yet been implemented in the module.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)
