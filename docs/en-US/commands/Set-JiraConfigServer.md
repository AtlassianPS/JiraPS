---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Set-JiraConfigServer/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Set-JiraConfigServer/
---
# Set-JiraConfigServer

## SYNOPSIS

Defines the configured URL for the JIRA server

## SYNTAX

```powershell
Set-JiraConfigServer [-Server] <Uri> [[-ConfigFile] <String>] [<CommonParameters>]
```

## DESCRIPTION

This function defines the configured URL for the JIRA server that JiraPS should manipulate.

By default, this is stored in a config.xml file at the module's root path.

## EXAMPLES

### EXAMPLE 1

```powershell
Set-JiraConfigServer 'https://jira.example.com:8080'
```

This example defines the server URL of the JIRA server configured in the JiraPS config file.

## PARAMETERS

### -Server

The base URL of the Jira instance.

```yaml
Type: Uri
Parameter Sets: (All)
Aliases: Uri

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigFile

Path where the file with the configuration will be stored.

> This parameter is not yet implemented

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [String]

## OUTPUTS

### [System.String]

## NOTES

Support for multiple configuration files is limited at this point in time,
but enhancements are planned for the next major release.
This can be tracked in [JiraPS#194](https://github.com/AtlassianPS/JiraPS/issues/194)

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication/)

[Get-JiraConfigServer](../Get-JiraConfigServer/)
