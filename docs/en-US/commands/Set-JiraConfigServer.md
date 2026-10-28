---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Set-JiraConfigServer/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Set-JiraConfigServer/
---
# Set-JiraConfigServer

## SYNOPSIS

Saves a Jira endpoint for compatibility with existing scripts.

## SYNTAX

```powershell
Set-JiraConfigServer [-Server] <uri> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Saves the endpoint in the JiraPS.LegacyEndpoint server profile.
This compatibility command does not create or select a live connection.
Use named server profiles with Connect-Jira -Profile for new scripts.

## EXAMPLES

### EXAMPLE 1

```powershell
Set-JiraConfigServer 'https://jira.example.com:8080'
```

Saves the Jira endpoint for use when no default connection is selected.

## PARAMETERS

### -Server

The base URL of the Jira instance.

```yaml
Type: Uri
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Uri
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Shows the profile update without saving it.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts before saving the endpoint profile.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### None

## NOTES

The selected connection takes precedence over this saved endpoint.
Authentication is supplied when creating a connection or through an explicit Credential override.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraConfigServer](../Get-JiraConfigServer/)
