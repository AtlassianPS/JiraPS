---
document type: cmdlet
external help file: JiraPS-help.xml
HelpUri: https://atlassianps.org/docs/JiraPS/commands/Move-JiraVersion/
Locale: en-DE
Module Name: JiraPS
ms.date: 04.22.2026
PlatyPS schema version: 2024-05-01
title: Move-JiraVersion
---

# Move-JiraVersion

## SYNOPSIS

Moves an existing Version in JIRA

## SYNTAX

### ByAfter (Default)

```
Move-JiraVersion -Version <Object> -After <Object> [-Credential <pscredential>] [<CommonParameters>]
```

### ByPosition

```
Move-JiraVersion -Version <Object> -Position <string> [-Credential <pscredential>]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function moves the Version for an existing Project in JIRA.
Moving the Version modifies the order/sequence of the Version in relation to other Versions.

## EXAMPLES

### EXAMPLE 1

Move-JiraVersion -Version 10 -After 9


This example moves the Version with ID 10 after the Version with ID 9.

### EXAMPLE 2

Move-JiraVersion -Version $myVersionObject -After $otherVersionObject


This example moves the Version object after the other Version object.

### EXAMPLE 3

Move-JiraVersion -Version $myVersionObject -Position Earliest


This example moves the Version object to the earliest position.

## PARAMETERS

### -After

Version Object or ID to move Version after.

```yaml
Type: System.Object
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
Type: System.Management.Automation.PSCredential
DefaultValue: ''
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
Type: System.String
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

Version Object or ID to move.

```yaml
Type: System.Object
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

{{ Fill in the Description }}

### System.Object

{{ Fill in the Description }}

## OUTPUTS

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.


## RELATED LINKS

- [Online Version](https://atlassianps.org/docs/JiraPS/commands/Move-JiraVersion/)
- [Get-JiraVersion](../Get-JiraVersion/)
- [New-JiraVersion](../New-JiraVersion/)
- [Remove-JiraVersion](../Remove-JiraVersion/)
- [Set-JiraVersion](../Set-JiraVersion/)
