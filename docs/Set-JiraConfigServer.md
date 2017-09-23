---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Set-JiraConfigServer

## SYNOPSIS
Defines the configured URL for the JIRA server

## SYNTAX

```
Set-JiraConfigServer [-Server] <String> [-ConfigFile <String>]
```

## DESCRIPTION
This function defines the configured URL for the JIRA server that JiraPS should manipulate.
By default, this is stored in a config.xml file at the module's root path.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Set-JiraConfigServer 'https://jira.example.com:8080'
```

This example defines the server URL of the JIRA server configured in the JiraPS config file.

### -------------------------- EXAMPLE 2 --------------------------
```
Set-JiraConfigServer -Server 'https://jira.example.com:8080' -ConfigFile C:\jiraconfig.xml
```

This example defines the server URL of the JIRA server configured at C:\jiraconfig.xml.

## PARAMETERS

### -Server
The base URL of the Jira instance.

```yaml
Type: String
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

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
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

