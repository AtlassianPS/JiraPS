---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Get-JiraConfigServer

## SYNOPSIS
Obtains the configured URL for the JIRA server

## SYNTAX

```
Get-JiraConfigServer [[-ConfigFile] <String>]
```

## DESCRIPTION
This function returns the configured URL for the JIRA server that JiraPS should manipulate.
By default, this is stored in a config.xml file at the module's root path.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-JiraConfigServer
```

Returns the server URL of the JIRA server configured in the JiraPS config file.

### -------------------------- EXAMPLE 2 --------------------------
```
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

## INPUTS

### This function does not accept pipeline input.

## OUTPUTS

### [System.String]

## NOTES
Support for multiple configuration files is limited at this point in time, but enhancements are planned for a future update.

## RELATED LINKS

