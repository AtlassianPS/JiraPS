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

Moves an existing Version in JIRA

## SYNTAX

### ByAfter (Default)

```powershell
Move-JiraVersion -Version <Object> -After <Object> [-Credential <pscredential>] [<CommonParameters>]
```

### ByPosition

```powershell
Move-JiraVersion -Version <Object> -Position <string> [-Credential <pscredential>]
 [<CommonParameters>]
```

## DESCRIPTION

This function moves the Version for an existing Project in JIRA.
Moving the Version modifies the order/sequence of the Version in relation to other Versions.

## EXAMPLES

### EXAMPLE 1

```powershell
Move-JiraVersion -Version 10 -After 9
```

This example moves the Version with ID 10 after the Version with ID 9.

### EXAMPLE 2

```powershell
Move-JiraVersion -Version $myVersionObject -After $otherVersionObject
```

This example moves the Version object after the other Version object.

### EXAMPLE 3

```powershell
Move-JiraVersion -Version $myVersionObject -Position Earliest
```

This example moves the Version object to the earliest position.

## PARAMETERS

### -After

Version Object or ID to move Version after.

```yaml
Type: Object
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

### -Position

The new Position for the Version

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
AcceptedValues:
- First
- Last
- Earlier
- Later
HelpMessage: ''
```

### -Version

Version Object or ID to move.

```yaml
Type: Object
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### JiraPS.Version

## OUTPUTS

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraVersion](../Get-JiraVersion/)

[New-JiraVersion](../New-JiraVersion/)

[Remove-JiraVersion](../Remove-JiraVersion/)

[Set-JiraVersion](../Set-JiraVersion/)
