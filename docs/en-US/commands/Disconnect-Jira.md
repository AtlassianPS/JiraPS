---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Disconnect-Jira/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Disconnect-Jira/
---
# Disconnect-Jira

## SYNOPSIS

Disconnect Jira locally and invalidate retained handles.

## SYNTAX

### Default (Default)

```powershell
Disconnect-Jira [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Object

```powershell
Disconnect-Jira -Connection <AtlassianPS.Connection> [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Name

```powershell
Disconnect-Jira -Name <string> [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Id

```powershell
Disconnect-Jira -Id <int> [-WhatIf] [-Confirm] [<CommonParameters>]
```

### All

```powershell
Disconnect-Jira -All [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Disconnect Jira locally and invalidate retained handles.
Disconnecting clears that connection's cached responses, while selecting an existing connection retains its cache.

## EXAMPLES

### EXAMPLE 1

```powershell
$work | Disconnect-Jira
```

Invalidate one retained handle.

### EXAMPLE 2

```powershell
Disconnect-Jira
```

Disconnect only the Jira default.

### EXAMPLE 3

```powershell
Disconnect-Jira -All
```

Disconnect all Jira connections.

### EXAMPLE 4

```powershell
Disconnect-Jira -Name work
```

Disconnect by name.

### EXAMPLE 5

```powershell
Disconnect-Jira -Id $work.Id
```

Disconnect by ID.

## PARAMETERS

### -All

Disconnect every Jira connection.
Without a selector or All, Disconnect-Jira removes only the current Jira default.

```yaml
Type: SwitchParameter
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: All
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
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

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.Connection

## OUTPUTS

None.

## NOTES

Connections belong to one runspace and are never persisted as profiles.

## RELATED LINKS

[Shared authentication](https://atlassianps.org/docs/AtlassianPS.Configuration/about/authentication.html)

[Jira authentication](https://atlassianps.org/docs/JiraPS/about/authentication.html)
