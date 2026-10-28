---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraVersion/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraVersion/
---
# Get-JiraVersion

## SYNOPSIS

Returns versions in a Jira project.

## SYNTAX

### Version (Default)

```
Get-JiraVersion [-Version] <AtlassianPS.JiraPS.Version[]> [-PageSize <int>] [-Connection <AtlassianPS.Connection>]
 [-IncludeTotalCount] [-Skip <ulong>] [-First <ulong>] [<CommonParameters>]
```

### Project

```
Get-JiraVersion -Project <AtlassianPS.JiraPS.Project[]> [-Name <string[]>] [-Sort <string>] [-PageSize <int>]
 [-Connection <AtlassianPS.Connection>] [-IncludeTotalCount] [-Skip <ulong>] [-First <ulong>] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

Retrieves exact versions or lists versions belonging to projects.
Name patterns match any requested pattern without duplicate output.
First and Skip apply after filtering across the input projects.

## EXAMPLES

### Example 1

```powershell
Get-JiraVersion -Version 10001
```

Look up a version by its numeric ID.

### Example 2

```powershell
Get-JiraVersion -Project PROJ -Name 'v3*', 'v4*' -Skip 1 -First 5
```

Return matching project versions after applying name patterns and output limits.

### Example 3

```powershell
Get-JiraProject -Project PROJ | Get-JiraVersion
```

List versions for a typed project passed through the pipeline.

## PARAMETERS

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

### -First

Maximum number of matching records to return.

```yaml
Type: UInt64
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

### -IncludeTotalCount

Return total-count information before the records.
Accuracy is unknown when Jira does not provide a total.

```yaml
Type: SwitchParameter
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

### -Name

Wildcard name patterns for project versions.
A version matching any pattern is returned once.
First and Skip apply after matching.

```yaml
Type: String[]
DefaultValue: '"*"'
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Project
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

Number of records requested per page.
Use First to limit output and Skip to skip records.

```yaml
Type: Int32
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

Project keys, IDs or typed project objects whose versions to list.

```yaml
Type: AtlassianPS.JiraPS.Project[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Key
ParameterSets:
- Name: Project
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Skip

Number of matching records to skip before returning output.

```yaml
Type: UInt64
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
* releaseDate.

```yaml
Type: String
DefaultValue: '"name"'
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Project
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Version

Numeric version IDs or typed version objects for exact lookup.

```yaml
Type: AtlassianPS.JiraPS.Version[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
ParameterSets:
- Name: Version
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

### AtlassianPS.JiraPS.Version[]

### AtlassianPS.JiraPS.Project[]

## OUTPUTS

### AtlassianPS.JiraPS.Version

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraProject](../Get-JiraProject/)

[New-JiraVersion](../New-JiraVersion/)

[Remove-JiraVersion](../Remove-JiraVersion/)

[Set-JiraVersion](../Set-JiraVersion/)

[Move-JiraVersion](../Move-JiraVersion/)
