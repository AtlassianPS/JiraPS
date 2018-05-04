---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraConfigServer/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraConfigServer/
---
# Get-JiraConfigServer

## SYNOPSIS

Obtains the configured URL for the JIRA server

## SYNTAX

```powershell
Get-JiraConfigServer [[-ConfigFile] <String>] [<CommonParameters>]
```

## DESCRIPTION

This function returns the configured URL for the JIRA server that JiraPS should manipulate.

By default, this is stored in a config.xml file at the module's root path.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraConfigServer
```

Returns the server URL of the JIRA server configured in the JiraPS config file.

### EXAMPLE 2

```powershell
Get-JiraConfigServer -ConfigFile C:\jiraconfig.xml
```

Returns the server URL of the JIRA server configured at C:\jiraconfig.xml.

## PARAMETERS

### -ConfigFile

Path to the configuration file, if not the default.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [System.String]

## NOTES

Support for multiple configuration files is limited at this point in time, but enhancements are planned for a future update.

<TODO: link to issue for tracking>

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)
