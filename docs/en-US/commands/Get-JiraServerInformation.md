---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraServerInformation/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraServerInformation/
---
# Get-JiraServerInformation

## SYNOPSIS

This function returns the information about the JIRA Server

## SYNTAX

```powershell
Get-JiraServerInformation [[-Credential] <pscredential>] [-Force] [<CommonParameters>]
```

## DESCRIPTION

This functions shows all the information about the JIRA server, such as version, time, etc.

The result is cached for 5 minutes to improve performance.
Use the `-Force` parameter to bypass the cache and re-fetch from the server.
You can also use `Clear-JiraCache -Type ServerInfo` to manually clear the cache.

The returned object includes a `DeploymentType` property (`Cloud` or `Server`) that JiraPS uses internally to adapt API calls for Jira Cloud vs.
Data Center/Server.
If the API call fails or the response lacks a `deploymentType` field (older Jira Server versions), `DeploymentType` defaults to `Server`.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraServerInformation
```

This example returns information about the JIRA server.
Subsequent calls return the cached result.

### EXAMPLE 2

```powershell
Get-JiraServerInformation -Force
```

Bypasses the cache and re-fetches server information from the API.
Use this after a Jira upgrade or configuration change.

### EXAMPLE 3

```powershell
(Get-JiraServerInformation).DeploymentType
```

Returns `Cloud` or `Server`, indicating which Jira platform is in use.

## PARAMETERS

### -Credential

Credentials to use to connect to JIRA.
If not specified, this function will use anonymous access.

```yaml
Type: System.Management.Automation.PSCredential
DefaultValue: '[System.Management.Automation.PSCredential]::Empty'
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Force

Bypasses the cached server information and re-fetches from the API.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### JiraPS.ServerInfo

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

The result is cached for 5 minutes after the first successful call.
Subsequent calls return the cached value without making an API request.
Use `-Force` to manually refresh the cache, or `Clear-JiraCache -Type ServerInfo` to clear it.
If the API call fails (e.g., network error, server not configured),
a stub object with `DeploymentType = 'Server'` is returned to allow operations to continue.

JiraPS uses `DeploymentType` to determine whether to use Cloud-specific
API behavior (e.g., `accountId` instead of `username`, API v3 endpoints).
Jira Cloud returns `"Cloud"`, while Data Center and older Server instances
return `"Server"` or omit the field entirely (defaulting to `"Server"`).

## RELATED LINKS
