---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Add-JiraIssueComment/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Add-JiraIssueComment/
---
# Add-JiraIssueComment

## SYNOPSIS

Adds a comment to an existing JIRA issue

## SYNTAX

```powershell
Add-JiraIssueComment [-Comment] <string> [-Issue] <Issue> [[-VisibleRole] <string>]
 [[-Credential] <pscredential>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function adds a comment to an existing issue in JIRA.
You can optionally set the visibility of the comment (All Users, Developers, or Administrators).

On **Jira Cloud**, the `-Comment` text is interpreted as Markdown and converted to Atlassian Document Format (ADF) before being sent, so familiar Markdown syntax (headings, bold/italic, lists, fenced code blocks, links, Markdown tables) renders as rich text in the issue.
On **Jira Server / Data Center**, the text is sent verbatim and the legacy wiki-markup syntax (`*bold*`, `_italic_`, `||header||`, `{code}`) continues to apply.
See [`ConvertTo-AtlassianDocumentFormat`](../ConvertTo-AtlassianDocumentFormat/) for the supported Markdown subset.

## EXAMPLES

### EXAMPLE 1

```powershell
Add-JiraIssueComment -Comment "Test comment" -Issue "TEST-001"
```

This example adds a simple comment to the issue TEST-001.

### EXAMPLE 2

```powershell
Get-JiraIssue "TEST-002" | Add-JiraIssueComment "Test comment from PowerShell"
```

This example illustrates pipeline use from `Get-JiraIssue` to `Add-JiraIssueComment`.

### EXAMPLE 3

```powershell
Get-JiraIssue -Query 'project = "TEST" AND created >= -5d' |
    Add-JiraIssueComment "This issue has been cancelled per Vice President's orders."
```

This example illustrates commenting on all projects which match a given JQL query.
It would be best to validate the query first to make sure the query returns the expected issues!

### EXAMPLE 4

```powershell
$summary = Get-JiraIssue -Query 'project = TEST AND status != Done AND assignee = currentUser()' |
    ConvertTo-JiraTable -Property Key, Summary, Status, Priority
Add-JiraIssueComment -Issue TEST-100 -Comment "My open issues:`n$summary"
```

This example assembles a wiki-markup table of the caller's open issues and posts it as a comment on the parent ticket TEST-100 — a typical status-update or stand-up workflow.
The JQL used here works on any Jira deployment (Core, Service Management, Software).
`ConvertTo-JiraTable` is the canonical way to embed tabular data in a Jira **Server / Data Center** comment.
On Jira **Cloud** use a Markdown table instead (see Example 6) because `||header||` wiki-markup syntax does not survive the Markdown → ADF conversion and renders as literal text.

### EXAMPLE 5

```powershell
$comment = Get-Process | ConvertTo-JiraTable
Add-JiraIssueComment $comment -Issue TEST-003
```

`ConvertTo-JiraTable` accepts any `PSObject` pipeline, so non-Jira data — here, the local process list — can also be tabulated and added to a comment.

### EXAMPLE 6

```powershell
$body = @"
## Deployment summary

* Build: **1.2.3**
* Status: _green_

| Service | Version |
| ------- | ------- |
| api     | 1.2.3   |
| web     | 1.2.3   |
"@
Add-JiraIssueComment -Issue TEST-100 -Comment $body
```

This example posts a richly-formatted Markdown comment to TEST-100.
On Jira **Cloud** the heading, bold/italic emphasis, bullet list, and Markdown table are converted to ADF and render natively.
On Jira **Server / Data Center** the text is posted verbatim — Markdown is not interpreted server-side, so use wiki-markup (`h2.`, `*bold*`, `||header||`, …) for the same effect there.

## PARAMETERS

### -Comment

Comment that should be added to JIRA.

```yaml
Type: String
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

### -Credential

Credentials to use to connect to JIRA.
If not specified, this function will use anonymous access.

```yaml
Type: PSCredential
DefaultValue: '[System.Management.Automation.PSCredential]::Empty'
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 3
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Issue

Issue that should be commented upon.

Can be a `AtlassianPS.JiraPS.Issue` object, issue key, or internal issue ID.

```yaml
Type: Issue
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Key
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -VisibleRole

Visibility of the comment.
Defines if the comment should be publicly visible, viewable to only developers, or only administrators.

Allowed values are:

- `All Users`
- `Developers`
- `Administrators`

```yaml
Type: String
DefaultValue: All Users
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
AcceptedValues:
- All Users
- Developers
- Administrators
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

### AtlassianPS.JiraPS.Issue

Pipe a AtlassianPS.JiraPS.Issue object to add a comment to it.

## OUTPUTS

### AtlassianPS.JiraPS.Comment

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraIssue](../Get-JiraIssue/)

[Get-JiraIssueComment](../Get-JiraIssueComment/)

[ConvertTo-JiraTable](../ConvertTo-JiraTable/)
