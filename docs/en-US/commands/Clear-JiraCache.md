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

Cached data includes: - Fields (from `Get-JiraField`) - Issue Types (from `Get-JiraIssueType`) - Priorities (from `Get-JiraPriority`) - Statuses - Server Information (from `Get-JiraServerInformation`)

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
The next call to `Get-JiraField` will fetch
fresh data from the server.

### EXAMPLE 3

```powershell
Clear-JiraCache -Type ServerInfo
Get-JiraServerInformation
```

Clears cached server information and fetches fresh data.

## PARAMETERS

### -Type

The type of cached data to clear.

Valid values are:
- `All` (default): Clears all cached data
- `Fields`: Clears cached field metadata
- `IssueTypes`: Clears cached issue types
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

## OUTPUTS

## NOTES

The cache is stored in module-level variables and is specific to each PowerShell session.
Restarting PowerShell will also clear the cache.

Functions like `Get-JiraField` also support a `-Force` parameter that bypasses
the cache for a single call without clearing the entire cache.

## RELATED LINKS

[Get-JiraField](../Get-JiraField/)

[Get-JiraIssueType](../Get-JiraIssueType/)

[Get-JiraServerInformation](../Get-JiraServerInformation/)
