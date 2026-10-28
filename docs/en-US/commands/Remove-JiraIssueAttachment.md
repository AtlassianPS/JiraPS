---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraIssueAttachment/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Remove-JiraIssueAttachment/
---
# Remove-JiraIssueAttachment

## SYNOPSIS

Removes an attachment from a Jira issue.

## SYNTAX

### byId (Default)

```powershell
Remove-JiraIssueAttachment [-Attachment] <AtlassianPS.JiraPS.Attachment[]> [-Connection <AtlassianPS.Connection>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### byIssue

```powershell
Remove-JiraIssueAttachment [-Issue] <AtlassianPS.JiraPS.Issue> [-FileName <string[]>] [-Connection <AtlassianPS.Connection>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

This function removes an attachment from a Jira issue.

## EXAMPLES

### Example 1

```powershell
Remove-JiraIssueAttachment -AttachmentId 10039
```

Removes attachment with ID of 10039

### Example 2

```powershell
Get-JiraIssueAttachment -Issue FOO-1234 | Remove-JiraIssueAttachment
```

Removes all attachments from issue FOO-1234

### Example 3

```powershell
Remove-JiraIssueAttachment -Issue FOO-1234 -FileName '*.png' -force
```

Removes all *.png attachments from issue FOO-1234 without prompting for confirmation

## PARAMETERS

### -Attachment

Positive attachment IDs or typed attachment objects.
Use Issue and optional FileName to select attachments belonging to an issue.

```yaml
Type: AtlassianPS.JiraPS.Attachment[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
- AttachmentId
ParameterSets:
- Name: byId
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
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

### -FileName

Name of the file to delete.

```yaml
Type: String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: byIssue
  Position: Named
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
- Name: byIssue
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
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

### AtlassianPS.JiraPS.Attachment[]

## OUTPUTS

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Add-JiraIssueAttachment](../Add-JiraIssueAttachment/)

[Get-JiraIssue](../Get-JiraIssue/)

[Get-JiraIssueAttachment](../Get-JiraIssueAttachment/)
