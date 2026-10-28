---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueLink/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueLink/
---
# Get-JiraIssueLink

## SYNOPSIS

Returns a specific issueLink from Jira

## SYNTAX

```
Get-JiraIssueLink [-IssueLink] <AtlassianPS.JiraPS.IssueLink[]> [[-Connection] <AtlassianPS.Connection>] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

This function returns information regarding a specified issueLink from Jira.

## EXAMPLES

### Example 1

```powershell
Get-JiraIssueLink -IssueLink 1234
```

Retrieve a typed issue-link record by ID.

### Example 2

```powershell
1234 | Get-JiraIssueLink
```

Retrieve an issue link through the typed selector pipeline.

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
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IssueLink

Positive issue-link IDs or typed IssueLink objects.

```yaml
Type: AtlassianPS.JiraPS.IssueLink[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
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

### AtlassianPS.JiraPS.IssueLink[]

## OUTPUTS

### JiraPS.IssueLink

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Add-JiraIssueLink](../Add-JiraIssueLink/)

[Get-JiraIssueLinkType](../Get-JiraIssueLinkType/)

[Remove-JiraIssueLink](../Remove-JiraIssueLink/)
