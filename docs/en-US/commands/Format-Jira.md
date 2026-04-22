---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Format-Jira/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Format-Jira/
---
# Format-Jira

## SYNOPSIS

Converts an object into a table formatted according to JIRA's markdown syntax

## SYNTAX

```powershell
Format-Jira [-InputObject] <psobject[]> [[-Property] <Object[]>] [<CommonParameters>]
```

## DESCRIPTION

Converts an object into a table formatted according to JIRA's markdown syntax.
This cmdlet formats PowerShell objects as JIRA-compatible markdown tables that can be used in issue comments or descriptions.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-Process | Format-Jira | Add-JiraIssueComment -Issue TEST-001
```

This example illustrates converting the output from `Get-Process` into a JIRA table, which is then added as a comment to issue TEST-001.

### EXAMPLE 2

```powershell
Get-Process chrome | Format-Jira Name,Id,VM
```

This example obtains all Google Chrome processes, then creates a JIRA table with only the Name,ID, and VM properties of each object.

## PARAMETERS

### -InputObject

Object to format.

```yaml
Type: PSObject[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: true
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Property

List of properties to display.
If omitted, only the default properties will be shown.

To display all properties, use `-Property *`.

```yaml
Type: Object[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
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

### System.Management.Automation.PSObject[]

## OUTPUTS

### System.String

## NOTES

Like the native `Format-*` cmdlets, this is a destructive operation.

Remember to "filter left, format right!"

## RELATED LINKS
