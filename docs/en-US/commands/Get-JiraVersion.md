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

### byId

```powershell
Get-JiraVersion -Id <int[]> [-PageSize <uint>] [-Credential <pscredential>] [-IncludeTotalCount] [-Skip <ulong>]
 [-First <ulong>] [<CommonParameters>]
```

### byInputVersion (Default)

```powershell
Get-JiraVersion [-InputVersion] <AtlassianPS.JiraPS.Version> [-PageSize <uint>] [-Credential <pscredential>]
 [-IncludeTotalCount] [-Skip <ulong>] [-First <ulong>] [<CommonParameters>]
```

### byProject

```powershell
Get-JiraVersion [-Project] <string[]> [-Name <string[]>] [-Sort <string>] [-PageSize <uint>]
 [-Credential <pscredential>] [-IncludeTotalCount] [-Skip <ulong>] [-First <ulong>] [<CommonParameters>]
```

### byInputProject

```powershell
Get-JiraVersion [-InputProject] <AtlassianPS.JiraPS.Project[]> [-Name <string[]>] [-Sort <string>]
 [-PageSize <uint>] [-Credential <pscredential>] [-IncludeTotalCount] [-Skip <ulong>] [-First <ulong>]
 [<CommonParameters>]
```

## DESCRIPTION

Returns versions visible to the current user in the selected project.

## EXAMPLES

### Example 1

```powershell
Get-JiraVersion -Project $ProjectKey
```

Returns all versions visible to the current user in the project.

### Example 2

```powershell
Get-JiraVersion -Project $ProjectKey -Name '1.0.0.0'
```

Returns the version named 1.0.0.0 in the project.

### Example 3

```powershell
Get-JiraProject 'FOO', 'BAR' | Get-JiraVersion -Name 'v1.0', 'v2.0'
```

Returns versions named v1.0 and v2.0 from projects FOO and BAR.

### Example 4

```powershell
Get-JiraVersion -Id '66596'
```

Returns the version with ID 66596.
The command uses anonymous access when no credentials or JiraPS session are available.

## PARAMETERS

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

### -First

Indicates how many items to return.

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

### -Id

The version ID.

```yaml
Type: Int32[]
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

### -InputProject

A project object to search.

```yaml
Type: AtlassianPS.JiraPS.Project[]
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

A version object to search for.

```yaml
Type: AtlassianPS.JiraPS.Version
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

The version name.

```yaml
Type: String[]
DefaultValue: '"*"'
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
Type: UInt32
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

Project key of a project to search.

```yaml
Type: String[]
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
AcceptedValues:
- sequence
- name
- startDate
- releaseDate
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable.
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.Version


### AtlassianPS.JiraPS.Project

## OUTPUTS

### AtlassianPS.JiraPS.Version

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent Jira session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to Jira.

## RELATED LINKS

[Get-JiraProject](../Get-JiraProject/)

[New-JiraVersion](../New-JiraVersion/)

[Remove-JiraVersion](../Remove-JiraVersion/)

[Set-JiraVersion](../Set-JiraVersion/)

[Move-JiraVersion](../Move-JiraVersion/)
