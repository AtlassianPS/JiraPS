---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraResponseHeaderLogConfiguration/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraResponseHeaderLogConfiguration/
---
# Get-JiraResponseHeaderLogConfiguration

## SYNOPSIS

Returns the current Jira response-header logging configuration.

## SYNTAX

```powershell
Get-JiraResponseHeaderLogConfiguration [<CommonParameters>]
```

## DESCRIPTION

Returns the configuration object set by `Set-JiraResponseHeaderLogConfiguration`, or `$null` when response-header logging is disabled.

The configuration is stored in module-scoped memory.
It survives normal cmdlet calls in the current module instance and is cleared when the module is forcefully reloaded.

## EXAMPLES

### EXAMPLE 1

```powershell
Set-JiraResponseHeaderLogConfiguration -Include 'X-A*'
Get-JiraResponseHeaderLogConfiguration
```

Returns the active configuration object.

### EXAMPLE 2

```powershell
Get-JiraResponseHeaderLogConfiguration
```

Returns `$null` when response-header logging has not been configured or has been disabled.

## PARAMETERS

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

The configuration affects only the current module instance.
Forcefully reloading the module clears the setting.

## RELATED LINKS

[Set-JiraResponseHeaderLogConfiguration](../Set-JiraResponseHeaderLogConfiguration/)

[Invoke-JiraMethod](../Invoke-JiraMethod/)
