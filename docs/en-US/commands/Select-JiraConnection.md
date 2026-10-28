---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Select-JiraConnection/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Select-JiraConnection/
---
# Select-JiraConnection

## SYNOPSIS

Select an active connection as the Jira default.

## SYNTAX

### Object (Default)

```
Select-JiraConnection -Connection <AtlassianPS.Connection> [<CommonParameters>]
```

### Name

```
Select-JiraConnection -Name <string> [<CommonParameters>]
```

### Id

```
Select-JiraConnection -Id <int> [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

Select an active connection as the Jira default.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraConnection -Name work | Select-JiraConnection
```

Select by pipeline object.

### EXAMPLE 2

```powershell
Select-JiraConnection -Name work
```

Select by name.

### EXAMPLE 3

```powershell
Select-JiraConnection -Id $work.Id
```

Select by runtime ID.

## PARAMETERS

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
- Name: Object
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Id

Runtime numeric connection ID, unique across products for the current shared runtime.

```yaml
Type: Int32
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Id
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Name

Friendly connection name, unique without case sensitivity within Jira.

```yaml
Type: String
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Name
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
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

### AtlassianPS.Connection

## OUTPUTS

### AtlassianPS.Connection

## NOTES

Connections belong to one runspace and are never persisted as profiles.

## RELATED LINKS

[Shared authentication](https://atlassianps.org/docs/AtlassianPS.Configuration/about/authentication.html)

[Jira authentication](https://atlassianps.org/docs/JiraPS/about/authentication.html)
