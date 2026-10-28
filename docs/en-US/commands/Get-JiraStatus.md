---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraStatus/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraStatus/
---
# Get-JiraStatus

## SYNOPSIS

Returns issue status information from Jira.

## SYNTAX

### _All (Default)

```powershell
Get-JiraStatus [-Refresh] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

### _Search

```powershell
Get-JiraStatus [-Status] <AtlassianPS.JiraPS.Status[]> [-Refresh] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

## DESCRIPTION

This function returns Jira status objects.
Use it to retrieve all available statuses or to query one or more statuses by ID or name.
`-IdOrName` is provided as an alias for `-Status`.

Responses are cached for one hour per connection and resource.
Use `-Refresh` to fetch fresh data and replace the cached response.

## EXAMPLES

### Example 1

```powershell
Get-JiraStatus
```

Returns all available statuses.

### Example 2

```powershell
Get-JiraStatus -Status 1
```

Returns the status with ID 1.

### Example 3

```powershell
Get-JiraStatus -Status Open
```

Returns the status named Open.

### Example 4: Refresh metadata after a Jira configuration change

```powershell
Get-JiraStatus -Status Open -Refresh
```

Fetches the current metadata and replaces the cached response for this lookup.

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
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Status

Status objects, IDs or names to retrieve.
When an object contains both an ID and a name, its ID takes precedence.
Jira Cloud returns the first matching status when a name is shared by multiple statuses, so use an ID when the name is ambiguous.

```yaml
Type: AtlassianPS.JiraPS.Status[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- IdOrName
ParameterSets:
- Name: _Search
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Refresh

Fetch fresh data and replace the selected connection's cached response for the requested resource.

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

### AtlassianPS.JiraPS.Status[]

## OUTPUTS

### AtlassianPS.JiraPS.Status

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraIssue](../Get-JiraIssue/)

[Atlassian Cloud status lookup](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-workflow-statuses/#api-rest-api-3-status-idOrName-get)
