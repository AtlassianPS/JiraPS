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

```powershell
Move-JiraVersion -Version <AtlassianPS.JiraPS.Version> -After <AtlassianPS.JiraPS.Version>
 [-Credential <pscredential>] [<CommonParameters>]
```

### ByPosition

```powershell
Move-JiraVersion -Version <AtlassianPS.JiraPS.Version> -Position <string> [-Credential <pscredential>]
 [<CommonParameters>]
```

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
AcceptedValues:
- First
- Last
- Earlier
- Later
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable.
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.Version

## OUTPUTS

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent Jira session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to Jira.

## RELATED LINKS

[Get-JiraVersion](../Get-JiraVersion/)

[New-JiraVersion](../New-JiraVersion/)

[Remove-JiraVersion](../Remove-JiraVersion/)

[Set-JiraVersion](../Set-JiraVersion/)
