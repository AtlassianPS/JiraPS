---
document type: cmdlet
external help file: JiraPS-help.xml
HelpUri: https://atlassianps.org/docs/JiraPS/commands/Get-JiraVersion/
Locale: en-DE
Module Name: JiraPS
ms.date: 04.22.2026
PlatyPS schema version: 2024-05-01
title: Get-JiraVersion
---

# Get-JiraVersion

## SYNOPSIS

This function returns information about a JIRA Project's Version

## SYNTAX

### byId (Default)

```
Get-JiraVersion -Id <int[]> [-PageSize <uint>] [-Credential <pscredential>] [-IncludeTotalCount]
 [-Skip <ulong>] [-First <ulong>] [<CommonParameters>]
```

### byInputVersion

```
Get-JiraVersion [-InputVersion] <Version> [-PageSize <uint>] [-Credential <pscredential>]
 [-IncludeTotalCount] [-Skip <ulong>] [-First <ulong>] [<CommonParameters>]
```

### byProject

```
Get-JiraVersion [-Project] <string[]> [-Name <string[]>] [-Sort <string>] [-PageSize <uint>]
 [-Credential <pscredential>] [-IncludeTotalCount] [-Skip <ulong>] [-First <ulong>]
 [<CommonParameters>]
```

### byInputProject

```
Get-JiraVersion [-InputProject] <Project> [-Name <string[]>] [-Sort <string>] [-PageSize <uint>]
 [-Credential <pscredential>] [-IncludeTotalCount] [-Skip <ulong>] [-First <ulong>]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function provides information about JIRA Version

## EXAMPLES

### EXAMPLE 1

Get-JiraVersion -Project $ProjectKey


This example returns information about all JIRA Version visible to the current user for the project.

### EXAMPLE 2

Get-JiraVersion -Project $ProjectKey -Name '1.0.0.0'


This example returns the information of a specific Version.

### EXAMPLE 3

Get-JiraProject "FOO", "BAR" | Get-JiraVersion -Name "v1.0", "v2.0"


Get the Version with name "v1.0" and "v2.0" from both projects "FOO" and "BAR"

### EXAMPLE 4

Get-JiraVersion -ID '66596'


This example returns information about all JIRA Version visible to the current user
(or using anonymous access if a JiraPS session has not been defined) for the project.

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

### -First

Indicates how many items to return.

```yaml
Type: System.UInt64
DefaultValue: 18446744073709551615
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

The Version ID

```yaml
Type: System.Int32[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: byId
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IncludeTotalCount

Causes an extra output of the total count at the beginning.

Note this is actually a uInt64, but with a custom string representation.

```yaml
Type: System.Management.Automation.SwitchParameter
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

### -InputProject

A Project Object to search

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: byInputProject
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -InputVersion

A Version object to search for

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: byInputVersion
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Name

Jira Version Name

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Versions
ParameterSets:
- Name: byInputProject
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: byProject
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PageSize

Maximum number of results to fetch per call.

This setting can be tuned to get better performance according to the load on the server.

> Warning: too high of a PageSize can cause a timeout on the request.

```yaml
Type: System.UInt32
DefaultValue: 25
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

### -Project

Project key of a project to search

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Key
ParameterSets:
- Name: byProject
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Skip

Controls how many things will be skipped before starting output.

Defaults to 0.

```yaml
Type: System.UInt64
DefaultValue: 0
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

### -Sort

Define the order in which the versions should be sorted before returning.

Possible values are:

* sequence
* name
* startDate
* releaseDate

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: byInputProject
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: byProject
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

### JiraPS.Version

{{ Fill in the Description }}

### JiraPS.Project

{{ Fill in the Description }}

### System.Object

{{ Fill in the Description }}

## OUTPUTS

### JiraPS.Version

{{ Fill in the Description }}

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.


## RELATED LINKS

- [Online Version](https://atlassianps.org/docs/JiraPS/commands/Get-JiraVersion/)
- [Get-JiraProject](../Get-JiraProject/)
- [New-JiraVersion](../New-JiraVersion/)
- [Remove-JiraVersion](../Remove-JiraVersion/)
- [Set-JiraVersion](../Set-JiraVersion/)
- [Move-JiraVersion](../Move-JiraVersion/)
