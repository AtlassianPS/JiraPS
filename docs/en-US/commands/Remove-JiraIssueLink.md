---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraIssueLink/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Remove-JiraIssueLink/
---
# Remove-JiraIssueLink

## SYNOPSIS

Removes an issue link from a Jira issue.

## SYNTAX

### ByIssueLink (Default)

```
Remove-JiraIssueLink -IssueLink <AtlassianPS.JiraPS.IssueLink[]> [-Connection <AtlassianPS.Connection>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ByIssue

```
Remove-JiraIssueLink -Issue <AtlassianPS.JiraPS.Issue[]> [-Connection <AtlassianPS.Connection>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

This function removes an issue link from a Jira issue.

## EXAMPLES

### Example 1

```powershell
Remove-JiraIssueLink -IssueLink 1234, 2345
```

Removes two issue links with ID 1234 and 2345

### Example 2

```powershell
Get-JiraIssue -Query 'project = Project1 AND label = lingering' | Remove-JiraIssueLink
```

Removes all issue links for all issues in project Project1 and that have a label "lingering"

## PARAMETERS

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

### -Issue

Issue keys, numeric ID strings or typed issue objects.

```yaml
Type: AtlassianPS.JiraPS.Issue[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByIssue
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IssueLink

Positive issue-link IDs or typed issue-link objects.

```yaml
Type: AtlassianPS.JiraPS.IssueLink[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByIssueLink
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
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

### AtlassianPS.JiraPS.IssueLink[]

### AtlassianPS.JiraPS.Issue[]

## OUTPUTS

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Add-JiraIssueLink](../Add-JiraIssueLink/)

[Get-JiraIssue](../Get-JiraIssue/)

[Get-JiraIssueLink](../Get-JiraIssueLink/)
