---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Add-JiraIssueLink/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Add-JiraIssueLink/
---
# Add-JiraIssueLink

## SYNOPSIS

Adds a link between two issues on Jira.

## SYNTAX

```powershell
Add-JiraIssueLink [-IssueLink] <AtlassianPS.JiraPS.IssueLinkCreateRequest[]> [[-Comment] <string>]
 [[-Connection] <AtlassianPS.Connection>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

Creates a new link of the specified type between two issues.

## EXAMPLES

### Example 1

```powershell
$_issueLink = [AtlassianPS.JiraPS.IssueLinkCreateRequest]@{
    inwardIssue = [AtlassianPS.JiraPS.LinkedIssueRef]@{ key = 'TEST-01' }
    outwardIssue = [AtlassianPS.JiraPS.LinkedIssueRef]@{ key = 'TEST-10' }
    type = [AtlassianPS.JiraPS.IssueLinkTypeRef]@{ name = 'Composition' }
}
Add-JiraIssueLink -IssueLink $_issueLink
```

Creates a link "is part of" between TEST-01 and TEST-10

### Example 2

```powershell
$_issueLink = New-JiraIssueLinkRequest -Type 'Blocks' -FromIssue 'TEST-01' -ToIssue 'TEST-10'
Add-JiraIssueLink -IssueLink $_issueLink
```

Creates a link using the helper cmdlet's simple `-Type` / `-FromIssue` / `-ToIssue` signature.

## PARAMETERS

### -Comment

Write a comment to the issue.

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
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IssueLink

Positive issue-link IDs or typed issue-link objects.

```yaml
Type: AtlassianPS.JiraPS.IssueLinkCreateRequest[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
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

None.

## OUTPUTS

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraIssue](../Get-JiraIssue/)

[Get-JiraIssueLink](../Get-JiraIssueLink/)

[Get-JiraIssueLinkType](../Get-JiraIssueLinkType/)

[New-JiraIssueLinkRequest](../New-JiraIssueLinkRequest/)

[Remove-JiraIssueLink](../Remove-JiraIssueLink/)
