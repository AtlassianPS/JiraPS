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
New-JiraVersion -InputObject <AtlassianPS.JiraPS.Version> [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [-ConnectionName <String>] [-Uri <Uri>] [-EmailAddress <String>] [-ApiToken <Object>] [-PersonalAccessToken <Object>] [-Anonymous] [<CommonParameters>]
```

### byParameters

```powershell
New-JiraVersion -Name <String> -Project <AtlassianPS.JiraPS.Project> [-Description <String>] [-Archived <Boolean>] [-Released <Boolean>] [-ReleaseDate <DateTime>] [-StartDate <DateTime>] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [-ConnectionName <String>] [-Uri <Uri>] [-EmailAddress <String>] [-ApiToken <Object>] [-PersonalAccessToken <Object>] [-Anonymous] [<CommonParameters>]
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

Username/password or compatible Cloud email/token as PSCredential. Explicit input temporarily overrides the selected identity without inheriting cookies or changing the stored connection. An empty credential fails; omitted input uses the selected connection.

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

Friendly connection name, unique without case sensitivity within Jira.

```yaml
Type: String
Parameter Sets: byParameters
Aliases: None

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
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

Live shared connection for this operation. Session is a compatibility alias. The object must be active in this runspace and belong to Jira.

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

### -ConnectionName

Case-insensitive name of an active Jira connection. Server and ServerName are compatibility aliases. This parameter is mutually exclusive with Connection and a standalone endpoint.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Server, ServerName

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Uri

Standalone Jira product endpoint for this logical operation. Cannot be combined with Connection or ConnectionName. Supply one explicit authentication mode; use Anonymous for anonymous access. Normal HTTPS commercial Atlassian site URLs resolve cloudId and the API gateway automatically for ApiToken authentication.

```yaml
Type: Uri
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EmailAddress

Cloud authentication email for ApiToken. Email is an alias. An override must supply both its own email and token.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Email

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApiToken

Cloud API token as a nonempty string or SecureString. Supply the authentication email in the same call. The module normalizes the secret and resolves a normal Cloud site URL automatically.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PersonalAccessToken

Data Center PAT as a nonempty string or SecureString. PAT and BearerToken are aliases. No dummy username is required.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: PAT, BearerToken

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Anonymous

Explicit anonymous authentication when the Jira endpoint permits it. Never borrows the default connection identity.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: None

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

This function requires either the `-Credential` parameter to be passed or a persistent Jira session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to Jira.

## RELATED LINKS

[Get-JiraVersion](../Get-JiraVersion/)

[Remove-JiraVersion](../Remove-JiraVersion/)

[Set-JiraVersion](../Set-JiraVersion/)

[Get-JiraProject](../Get-JiraProject/)

[Move-JiraVersion](../Move-JiraVersion/)
