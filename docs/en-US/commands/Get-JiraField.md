---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraField/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraField/
---
# Get-JiraField

## SYNOPSIS

This function returns information about Jira fields.

## SYNTAX

### _All (Default)

```
Get-JiraField [-Refresh] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

### _Search

```
Get-JiraField [-Field] <AtlassianPS.JiraPS.Field[]> [-Refresh] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

This function provides information about Jira fields, or about one field in particular.
This is a good way to identify a field's ID by its name, or vice versa.

Typically, this information is only needed when identifying what fields are necessary to create or edit issues.
See `Get-JiraIssueCreateMetadata` for more details.

Results are cached for 60 minutes to reduce API calls.
Use the `-Refresh` parameter to fetch and replace the cached response and fetch fresh data from the server.

## EXAMPLES

### Example 1

```powershell
Get-JiraField
```

This example returns information about all Jira fields visible to the current user.

### Example 2

```powershell
Get-JiraField 'Key'
```

This example returns information about the Key field.

### Example 3

```powershell
Get-JiraField -Refresh
```

This example bypasses the cache and fetches fresh field data from the server.

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

### -Field

Field objects, field IDs or wildcard field names.
An exact ID takes precedence over a display-name match.

```yaml
Type: AtlassianPS.JiraPS.Field[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
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

### AtlassianPS.JiraPS.Field[]

## OUTPUTS

### AtlassianPS.JiraPS.Field

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

Results are cached for 60 minutes per server.
Use `-Refresh` to fetch and replace the cached response, or use `Clear-JiraCache -Type Fields` to clear all cached field data.

Remaining operations for `field` have not yet been implemented in the module.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraIssueCreateMetadata](../Get-JiraIssueCreateMetadata/)

[Clear-JiraCache](../Clear-JiraCache/)
