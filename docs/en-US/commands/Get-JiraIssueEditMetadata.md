---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueEditMetadata/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueEditMetadata/
---
# Get-JiraIssueEditMetadata

## SYNOPSIS

Returns metadata required to change an issue in JIRA

## SYNTAX

```
Get-JiraIssueEditMetadata [-Issue] <AtlassianPS.JiraPS.Issue> [[-Connection] <AtlassianPS.Connection>] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

This function returns metadata required to update an issue in JIRA - the fields that can be defined in the process of updating an issue.
This can be used to identify custom fields in order to pass them to `Set-JiraIssue`.

This function is particularly useful when your JIRA instance includes custom fields that are marked as mandatory.

## EXAMPLES

### Example 1

```powershell
Get-JiraIssue -Issue PROJ-1 | Get-JiraIssueEditMetadata
```

Retrieve edit metadata through a typed issue pipeline.

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

### -Issue

Issue keys, numeric ID strings or typed issue objects.

```yaml
Type: AtlassianPS.JiraPS.Issue
DefaultValue: ''
SupportsWildcards: false
Aliases: []
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

### AtlassianPS.JiraPS.Issue

## OUTPUTS

### JiraPS.Field

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[about_JiraPS_UpdatingIssues](../../about/updating-issues.html)

[Get-JiraField](../Get-JiraField/)

[Set-JiraIssue](../Set-JiraIssue/)
