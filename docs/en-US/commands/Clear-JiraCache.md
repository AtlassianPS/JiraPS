---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Clear-JiraCache/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Clear-JiraCache/
---
# Clear-JiraCache

## SYNOPSIS

Clears cached data stored by JiraPS.

## SYNTAX

```powershell
Clear-JiraCache [[-Type] <string>] [<CommonParameters>]
```

## DESCRIPTION

JiraPS caches certain API responses to improve performance and reduce API calls.
This function clears the cached data, either entirely or for a specific type of data.

Cached data includes:

- Fields (`Get-JiraField`)
- Issue types (`Get-JiraIssueType`)
- Issue link types (`Get-JiraIssueLinkType`)
- Priorities (`Get-JiraPriority`)
- Statuses (`Get-JiraStatus`)
- Server information (`Get-JiraServerInformation`)

Use this function when you need fresh data from the server, for example after making configuration changes in Jira.

## EXAMPLES

### EXAMPLE 1

```powershell
Clear-JiraCache
```

Clears all cached data.

### EXAMPLE 2

```powershell
Clear-JiraCache -Type Fields
```

Clears only the cached field data.
The next call to `Get-JiraField` will fetch fresh data from the server.

### EXAMPLE 3

```powershell
Clear-JiraCache -Type ServerInfo
Get-JiraServerInformation
```

Clears cached server information and fetches fresh data.

### Example 4: Clear link type metadata for all connections

```powershell
Clear-JiraCache -Type IssueLinkTypes
```

Clears catalogue and individual link type responses for every connection.
The next lookup fetches fresh data.

## PARAMETERS

### -Type

The type of cached data to clear.

Valid values are:

- `All` (default): Clears all cached data
- `Fields`: Clears cached field metadata
- `IssueTypes`: Clears cached issue types
- `IssueLinkTypes`: Clears cached issue link types
- `Priorities`: Clears cached priorities
- `Statuses`: Clears cached statuses
- `ServerInfo`: Clears cached server information

```yaml
Type: String
DefaultValue: All
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
AcceptedValues:
- All
- Fields
- IssueTypes
- IssueLinkTypes
- Priorities
- Statuses
- ServerInfo
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

None.

## NOTES

Responses are cached separately for each active connection and resource URI.
Switching the selected connection preserves its cache; disconnecting removes its entries.
This command clears matching entries across all connections in the current PowerShell session.
Restarting PowerShell will also clear the cache.

Fields, issue types, issue link types, priorities and statuses expire after one hour.
Server information expires after five minutes.

Use a getter's `-Refresh` switch to replace the selected connection's response for the requested resource.
Catalogue and individual lookup responses are separate entries; clear a type to invalidate all its responses.

## RELATED LINKS

[Get-JiraField](../Get-JiraField/)

[Get-JiraIssueType](../Get-JiraIssueType/)

[Get-JiraServerInformation](../Get-JiraServerInformation/)
