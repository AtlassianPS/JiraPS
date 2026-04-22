---
document type: cmdlet
external help file: JiraPS-help.xml
HelpUri: https://atlassianps.org/docs/JiraPS/commands/Get-JiraFilterPermission/
Locale: en-DE
Module Name: JiraPS
ms.date: 04.22.2026
PlatyPS schema version: 2024-05-01
title: Get-JiraFilterPermission
---

# Get-JiraFilterPermission

## SYNOPSIS

Fetch the permissions of a specific Filter.

## SYNTAX

### ById (Default)

```
Get-JiraFilterPermission [-Id] <uint[]> [-Credential <pscredential>] [<CommonParameters>]
```

### ByInputObject

```
Get-JiraFilterPermission [-Filter] <Filter> [-Credential <pscredential>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This allows the user to retrieve all the sharing permissions set for a Filter.

## EXAMPLES

### Example 1

Get-JiraFilterPermission -Filter (Get-JiraFilter 12345)
#-------
Get-JiraFilterPermission -Id 12345


Two methods for retrieving the permissions set for Filter 12345.

### Example 2

12345 | Get-JiraFilterPermission
#-------
Get-JiraFilter 12345 | Add-JiraFilterPermission


Two methods for retrieve the permissions set for Filter 12345 by using the pipeline.

The Id could be read from a file.

## PARAMETERS

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

### -Filter

Filter object from which to retrieve the permissions

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

### -Id

Id of the Filter from which to retrieve the permissions

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

### JiraPS.Filter

{{ Fill in the Description }}

## NOTES

This function requires either the `-Credential` parameter to be passed or
a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.


## RELATED LINKS

- [Online Version](https://atlassianps.org/docs/JiraPS/commands/Get-JiraFilterPermission/)
- [Get-JiraFilter](../Get-JiraFilter/)
- [Add-JiraFilterPermission](../Add-JiraFilterPermission/)
- [Remove-JiraFilterPermission](../Remove-JiraFilterPermission/)
