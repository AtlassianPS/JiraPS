---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Move-JiraVersion/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Move-JiraVersion/
---
# Move-JiraVersion

## SYNOPSIS

Moves an existing version in Jira.

## SYNTAX

### ByAfter (Default)

```
Move-JiraVersion -Version <AtlassianPS.JiraPS.Version> -After <AtlassianPS.JiraPS.Version> [-Connection <AtlassianPS.Connection>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ByPosition

```
Move-JiraVersion -Version <AtlassianPS.JiraPS.Version> -Position <string> [-Connection <AtlassianPS.Connection>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

This function moves the version for an existing project in Jira.
Moving the version modifies the order/sequence of the version in relation to other versions.

## EXAMPLES

### Example 1

```powershell
Move-JiraVersion -Version 10 -After 9
```

This example moves the version with ID 10 after the version with ID 9.

### Example 2

```powershell
Move-JiraVersion -Version $myVersionObject -After $otherVersionObject
```

This example moves the version object after the other version object.

### Example 3

```powershell
Move-JiraVersion -Version $myVersionObject -Position Earliest
```

This example moves the version object to the earliest position.

## PARAMETERS

### -After

Version object or ID to move version after.

```yaml
Type: AtlassianPS.JiraPS.Version
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByAfter
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

### -Position

The new Position for the version.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByPosition
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Version

Version object or ID to move.

```yaml
Type: AtlassianPS.JiraPS.Version
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
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

### AtlassianPS.JiraPS.Version

## OUTPUTS

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraVersion](../Get-JiraVersion/)

[New-JiraVersion](../New-JiraVersion/)

[Remove-JiraVersion](../Remove-JiraVersion/)

[Set-JiraVersion](../Set-JiraVersion/)
