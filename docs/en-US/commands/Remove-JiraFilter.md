---
document type: cmdlet
external help file: JiraPS-help.xml
HelpUri: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraFilter/
Locale: en-DE
Module Name: JiraPS
ms.date: 04.22.2026
PlatyPS schema version: 2024-05-01
title: Remove-JiraFilter
---

# Remove-JiraFilter

## SYNOPSIS

Removes an existing filter.

## SYNTAX

### ByInputObject (Default)

```
Remove-JiraFilter [-InputObject] <Filter> [-Credential <pscredential>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### ById

```
Remove-JiraFilter [-Id] <uint[]> [-Credential <pscredential>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function will remove a filter from Jira.
Deleting a filter removed is permanently from Jira.

## EXAMPLES

### Example 1

Remove-JiraFilter -InputObject (Get-JiraFilter "12345")


Removes the filter `12345` from Jira.

### Example 2

$filter = Get-JiraFilter "12345", "98765"
Remove-JiraFilter -InputObject $filter


Removes two filters (`12345` and `98765`) from Jira.

### Example 3

Get-JiraFilter "12345", "98765" | Remove-JiraFilter


Removes two filters (`12345` and `98765`) from Jira.

### Example 4

Get-JiraFilter -Favorite | Remove-JiraFilter -Confirm


Asks for each favorite filter confirmation to delete it.

### Example 5

$listOfFilters = 1,2,3,4
$listOfFilters | Remove-JiraFilter


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
Type: System.Object
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

{{ Fill in the Description }}

### System.Object

{{ Fill in the Description }}

### System.UInt32[]

{{ Fill in the Description }}

## OUTPUTS

## NOTES

This function requires either the `-Credential` parameter to be passed or
a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.


## RELATED LINKS

- [Online Version](https://atlassianps.org/docs/JiraPS/commands/Remove-JiraFilter/)
- [Get-JiraFilter](../Get-JiraFilter/)
- [New-JiraFilter](../New-JiraFilter/)
- [Set-JiraFilter](../Set-JiraFilter/)
