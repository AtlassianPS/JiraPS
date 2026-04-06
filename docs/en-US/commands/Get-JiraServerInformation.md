---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraServerInformation/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraServerInformation/
---
# Get-JiraServerInformation

## SYNOPSIS

This function returns the information about the JIRA Server

## SYNTAX

```powershell
Get-JiraServerInformation [[-Credential] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

This functions shows all the information about the JIRA server, such as version, time, etc.

The result is cached for the lifetime of the PowerShell session (or until `Set-JiraConfigServer` is called with a new URL). Use the `-Force` parameter to bypass the cache and re-fetch from the server.

The returned object includes a `DeploymentType` property (`Cloud` or `Server`) that JiraPS uses internally to adapt API calls for Jira Cloud vs. Data Center/Server. If the API call fails or the response lacks a `deploymentType` field (older Jira Server versions), `DeploymentType` defaults to `Server`.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraServerInformation
```

This example returns information about the JIRA server. Subsequent calls return the cached result.

### EXAMPLE 2

```powershell
Get-JiraServerInformation -Force
```

Bypasses the cache and re-fetches server information from the API. Use this after a Jira upgrade or configuration change.

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
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force

Bypasses the cached server information and re-fetches from the API.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [JiraPS.ServerInfo]

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

The result is cached in module scope after the first successful call.
Subsequent calls return the cached value without making an API request.
The cache is automatically cleared when `Set-JiraConfigServer` is called.
Use `-Force` to manually refresh the cache.
If the API call fails (e.g., network error, server not configured),
a stub object with `DeploymentType = 'Server'` is cached to avoid
repeated failing requests on every operation.

JiraPS uses `DeploymentType` to determine whether to use Cloud-specific
API behavior (e.g., `accountId` instead of `username`, API v3 endpoints).
Jira Cloud returns `"Cloud"`, while Data Center and older Server instances
return `"Server"` or omit the field entirely (defaulting to `"Server"`).

## RELATED LINKS
