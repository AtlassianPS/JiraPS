---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueAttachment/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueAttachment/
---
# Get-JiraIssueAttachment

## SYNOPSIS

Returns attachments of an issue in Jira.

## SYNTAX

```powershell
Get-JiraIssueAttachment [-Issue] <AtlassianPS.JiraPS.Issue> [[-FileName] <string>] [[-Connection] <AtlassianPS.Connection>] [<CommonParameters>]
```

## DESCRIPTION

This function obtains attachments from existing issues in Jira.

## EXAMPLES

### Example 1

```powershell
Get-JiraIssueAttachment -Issue TEST-001
```

This example returns all attachments from issue TEST-001.

### Example 2

```powershell
Get-JiraIssue TEST-002 | Get-JiraIssueAttachment
```

This example illustrates use of the pipeline to return all attachments from issue TEST-002.

### Example 3

```powershell
Get-JiraIssue TEST-002 | Get-JiraIssueAttachment -FileName '*.png'
```

Returns all attachments of issue TEST-002 where the filename ends in `.png`

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

### -FileName

File names to match.

This parameter supports wildcards.

```yaml
Type: String
DefaultValue: ''
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.Issue

## OUTPUTS

### AtlassianPS.JiraPS.Attachment

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)


[Add-JiraIssueAttachment](../Add-JiraIssueAttachment/)

[Get-JiraIssue](../Get-JiraIssue/)

[Remove-JiraIssueAttachment](../Remove-JiraIssueAttachment/)
