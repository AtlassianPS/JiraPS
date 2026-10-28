---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraPriority/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraPriority/
---
# Get-JiraPriority

## SYNOPSIS

Returns information about the available priorities in JIRA.

## SYNTAX

### _All (Default)

```powershell
Get-JiraPriority [-Refresh] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

### _Search

```powershell
Get-JiraPriority [-Id] <int[]> [-Refresh] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

## DESCRIPTION

Retrieves available priorities, or specific priorities by ID, as `AtlassianPS.JiraPS.Priority` objects.

Catalogue and ID responses are cached for one hour per connection and resource.
Use `-Refresh` to fetch fresh data and replace the cached response for the requested resource.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraPriority
```

This example returns all priorities on the Jira server.

### EXAMPLE 2

```powershell
Get-JiraPriority -ID 1
```

This example returns only the Priority with ID 1.

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

### -Id

ID of the priority to get.

```yaml
Type: Int32[]
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

### System.Int32[]

## OUTPUTS

### AtlassianPS.JiraPS.Priority

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

Remaining operations for `priority` have not yet been implemented in the module.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)
