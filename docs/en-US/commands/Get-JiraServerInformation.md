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
Get-JiraServerInformation [[-Connection] <AtlassianPS.Connection>] [-Refresh] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

This functions shows all the information about the JIRA server, such as version, time, etc.

The result is cached for 5 minutes to improve performance.
Use the `-Refresh` parameter to fetch and replace the cached response and re-fetch from the server.
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
Get-JiraServerInformation -Refresh
```

Bypasses the cache and re-fetches server information from the API.
Use this after a Jira upgrade or configuration change.

### EXAMPLE 3

```powershell
(Get-JiraServerInformation).DeploymentType
```

Returns `Cloud` or `Server`, indicating which Jira platform is in use.

## PARAMETERS

### -Connection

Active Jira connection for this operation.
When omitted, the command uses the selected Jira default.
Create connections with Connect-Jira; resolve names with Get-JiraConnection -Name.

```yaml
Type: AtlassianPS.Connection
DefaultValue: None
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

### -Refresh

Fetch fresh data and replace the selected connection's cached response.

```yaml
Type: SwitchParameter
DefaultValue: ''
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

None.

## OUTPUTS

### AtlassianPS.JiraPS.ServerInfo

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

The result is cached for 5 minutes after the first successful call.
Subsequent calls return the cached value without making an API request.
Use `-Refresh` to manually refresh the cache, or `Clear-JiraCache -Type ServerInfo` to clear it.
If the API call fails (e.g., network error, server not configured),
a stub object with `DeploymentType = 'Server'` is returned to allow operations to continue.

JiraPS uses `DeploymentType` to determine whether to use Cloud-specific
API behavior (e.g., `accountId` instead of `username`, API v3 endpoints).
Jira Cloud returns `"Cloud"`, while Data Center and older Server instances
return `"Server"` or omit the field entirely (defaulting to `"Server"`).

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)
