---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraFilter/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Remove-JiraFilter/
---
# Remove-JiraFilter

## SYNOPSIS

Removes an existing filter.

## SYNTAX

### ByInputObject (Default)

```powershell
Remove-JiraFilter [-InputObject] <Filter> [-Credential <pscredential>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### ById

```powershell
Remove-JiraFilter [-Id] <uint[]> [-Credential <pscredential>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

This function will remove a filter from Jira.
Deleting a filter removed is permanently from Jira.

## EXAMPLES

### Example 1

```powershell
Remove-JiraFilter -InputObject (Get-JiraFilter "12345")
```

Removes the filter `12345` from Jira.

### Example 2

```powershell
$filter = Get-JiraFilter "12345", "98765"
Remove-JiraFilter -InputObject $filter
```

Removes two filters (`12345` and `98765`) from Jira.

### Example 3

```powershell
Get-JiraFilter "12345", "98765" | Remove-JiraFilter
```

Removes two filters (`12345` and `98765`) from Jira.

### Example 4

```powershell
Get-JiraFilter -Favorite | Remove-JiraFilter -Confirm
```

Asks for each favorite filter confirmation to delete it.

### Example 5

```powershell
$listOfFilters = 1,2,3,4
$listOfFilters | Remove-JiraFilter
```

Remove filters with id "1", "2", "3" and "4".

This input allows for the ID of the filters to be stored in an array and passed
to the command.
(eg: `Get-Content` from a file with the ids)

## PARAMETERS

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
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

### -Credential

Credentials to use to connect to JIRA.
If not specified, this function will use anonymous access.

```yaml
Type: System.Management.Automation.PSCredential
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

### -Id

Id of the filter to be deleted.

Accepts integers over the pipeline.

```yaml
Type: System.UInt32[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ById
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -InputObject

Filter object to be deleted.

Object can be retrieved with `Get-JiraFilter`

```yaml
Type: JiraPS.Filter
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByInputObject
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: System.Management.Automation.SwitchParameter
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

### JiraPS.Filter


### System.UInt32[]

## OUTPUTS

## NOTES

This function requires either the `-Credential` parameter to be passed or
a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraFilter](../Get-JiraFilter/)

[New-JiraFilter](../New-JiraFilter/)

[Set-JiraFilter](../Set-JiraFilter/)
