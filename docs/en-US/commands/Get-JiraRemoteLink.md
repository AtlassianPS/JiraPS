---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraRemoteLink/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraRemoteLink/
---
# Get-JiraRemoteLink

## SYNOPSIS

Returns a remote link from a Jira issue.

## SYNTAX

```
Get-JiraRemoteLink [-Issue] <AtlassianPS.JiraPS.Issue> [[-LinkId] <int>] [[-Connection] <AtlassianPS.Connection>] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

This function returns information on remote links from a  Jira issue.

## EXAMPLES

### Example 1

```powershell
Get-JiraRemoteLink -Issue TEST-001
```

Returns information about all remote links from the issue "TEST-001"

### Example 2

```powershell
Get-JiraRemoteLink -Issue TEST-001 -LinkId 100000
```

Returns information about a specific remote link from the issue "TEST-001"

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
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Issue

Issue keys, numeric ID strings or typed issue objects.

```yaml
Type: AtlassianPS.JiraPS.Issue
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Key
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -LinkId

Get a single link by it's ID.

```yaml
Type: Int32
DefaultValue: 0
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
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

### AtlassianPS.JiraPS.Issue

## OUTPUTS

### AtlassianPS.JiraPS.Link

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Remove-JiraRemoteLink](../Remove-JiraRemoteLink/)
