---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/New-JiraVersion/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/New-JiraVersion/
---
# New-JiraVersion

## SYNOPSIS

Creates a new FixVersion in Jira.

## SYNTAX

### byObject (Default)

```powershell
New-JiraVersion [-InputObject] <AtlassianPS.JiraPS.Version> [-Credential <pscredential>] [-Connection <AtlassianPS.Connection>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### byParameters

```powershell
New-JiraVersion [-Name] <string> [-Project] <AtlassianPS.JiraPS.Project> [-Description <string>] [-Archived <bool>] [-Released <bool>] [-ReleaseDate <datetime>] [-StartDate <datetime>] [-Credential <pscredential>] [-Connection <AtlassianPS.Connection>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function creates a new FixVersion in Jira.

## EXAMPLES

### Example 1

```powershell
New-JiraVersion -Name '1.0.0.0' -Project 'RD'
```

This example creates a new Jira version named "1.0.0.0" in project "RD".

### Example 2

```powershell
$project = Get-JiraProject -Project 'RD'
New-JiraVersion -Name '1.0.0.0' -Project $project -ReleaseDate '2000-12-31'
```

Create a new version in project "RD" with a set release date.

### Example 3

```powershell
$version = Get-JiraVersion -Name '1.0.0.0' -Project 'RD'
$copy = @{
    Name        = $version.Name
    Project     = 'TEST'
    Description = $version.Description
    Archived    = $version.Archived
    Released    = $version.Released
}
if ($null -ne $version.StartDate) {
    $copy.StartDate = $version.StartDate
}
if ($null -ne $version.ReleaseDate) {
    $copy.ReleaseDate = $version.ReleaseDate
}
New-JiraVersion @copy
```

Copies the name, description and flags of version 1.0.0.0 from project RD to project TEST.
Start and release dates are copied when present.

## PARAMETERS

### -Archived

Create the version as archived.

```yaml
Type: Boolean
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: byParameters
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
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

Username/password or compatible Cloud email/token as PSCredential.
Explicit input temporarily overrides the selected identity without inheriting cookies or changing the stored connection.
An empty credential fails; omitted input uses the selected connection.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description

Description of the version.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: byParameters
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -InputObject

Version object that should be created on the server.

```yaml
Type: AtlassianPS.JiraPS.Version
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: byObject
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

Name of the version to create.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: byParameters
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Project

The project ID.

```yaml
Type: AtlassianPS.JiraPS.Project
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: byParameters
  Position: 1
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Released

Create the version as released.

```yaml
Type: Boolean
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: byParameters
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ReleaseDate

Date of the release.

```yaml
Type: DateTime
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: byParameters
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -StartDate

Date of the release.

```yaml
Type: DateTime
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: byParameters
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
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
Type: SwitchParameter
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

### -Connection

Active Jira connection for this operation.
Session is a compatibility alias.
When omitted, the command uses the selected Jira default.
Use Get-JiraConnection -Name to resolve a named connection.

```yaml
Type: AtlassianPS.Connection
Parameter Sets: (All)
Aliases: Session

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable.
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### AtlassianPS.JiraPS.Version

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraVersion](../Get-JiraVersion/)

[Remove-JiraVersion](../Remove-JiraVersion/)

[Set-JiraVersion](../Set-JiraVersion/)

[Get-JiraProject](../Get-JiraProject/)

[Move-JiraVersion](../Move-JiraVersion/)
