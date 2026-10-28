---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueLinkType/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueLinkType/
---
# Get-JiraIssueLinkType

## SYNOPSIS

Gets available issue link types.

## SYNTAX

### _All (Default)

```powershell
Get-JiraIssueLinkType [-Refresh] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

### _Search

```powershell
Get-JiraIssueLinkType [-LinkType] <AtlassianPS.JiraPS.IssueLinkType> [-Refresh] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

## DESCRIPTION

This function gets available issueLink types from a Jira server.
It can also return specific information about a single issueLink type.

This is a useful function for discovering data about issueLink types in order to create and modify issueLinks on issues.

Responses are cached for one hour per connection and resource.
Use `-Refresh` to fetch fresh data and replace the cached response.

## EXAMPLES

### Example 1

```powershell
Get-JiraIssueLinkType
```

This example returns all available links from the Jira server

### Example 2

```powershell
Get-JiraIssueLinkType -LinkType 1
```

This example returns information about the link type with ID 1.

### Example 3: Refresh metadata after a Jira configuration change

```powershell
Get-JiraIssueLinkType -LinkType 1 -Refresh
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

### -LinkType

The issue link type name or ID to search.

```yaml
Type: AtlassianPS.JiraPS.IssueLinkType
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: _Search
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
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

None.

## OUTPUTS

### AtlassianPS.JiraPS.IssueLinkType

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

Remaining operations for `issuetype` have not yet been implemented in the module.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Add-JiraIssueLink](../Add-JiraIssueLink/)

[Get-JiraIssueLink](../Get-JiraIssueLink/)

[Remove-JiraIssueLink](../Remove-JiraIssueLink/)
