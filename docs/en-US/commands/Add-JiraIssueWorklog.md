---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Add-JiraIssueWorklog/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Add-JiraIssueWorklog/
---
# Add-JiraIssueWorklog

## SYNOPSIS

Adds a worklog item to an existing JIRA issue

## SYNTAX

```powershell
Add-JiraIssueWorklog [-Comment] <string> [-Issue] <Object> [-TimeSpent] <timespan>
 [-DateStarted] <datetime> [[-VisibleRole] <string>] [[-Credential] <pscredential>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function adds a worklog item to an existing issue in JIRA.
You can optionally set the visibility of the item (All Users, Developers, or Administrators).

On **Jira Cloud**, the `-Comment` text is interpreted as Markdown and converted to Atlassian Document Format (ADF) before being sent.
The reverse path is also handled: when worklogs are read back from Cloud, the ADF comment payload is rendered to plain text on the returned `JiraPS.Worklogitem` object.
On **Jira Server / Data Center**, the comment is sent and read back verbatim and the legacy wiki-markup syntax continues to apply.
See [`ConvertTo-AtlassianDocumentFormat`](../ConvertTo-AtlassianDocumentFormat/) for the supported Markdown subset.

## EXAMPLES

### EXAMPLE 1

```powershell
Add-JiraIssueWorklog -Comment "Test comment" -Issue "TEST-001" -TimeSpent 60 -DateStarted (Get-Date)
```

This example adds a simple worklog item to the issue TEST-001.

### EXAMPLE 2

```powershell
Get-JiraIssue "TEST-002" | Add-JiraIssueWorklog "Test worklog item from PowerShell" -TimeSpent 60 -DateStarted (Get-Date)
```

This example illustrates pipeline use from `Get-JiraIssue` to `Add-JiraIssueWorklog`.

### EXAMPLE 3

```powershell
Get-JiraIssue -Query 'project = "TEST" AND created >= -5d' |
    Add-JiraIssueWorklog "This issue has been cancelled per Vice President's orders." -TimeSpent 60 -DateStarted (Get-Date)
```

This example illustrates logging work on all projects which match a given JQL query.
It would be best to validate the query first to make sure the query returns the expected issues!

### EXAMPLE 4

```powershell
$completed = Get-JiraIssue -Query 'project = TEST AND assignee = currentUser() AND status = Done AND updated >= -1d' |
    ConvertTo-JiraTable -Property Key, Summary
Add-JiraIssueWorklog -Issue TEST-100 -TimeSpent 14400 -DateStarted (Get-Date) -Comment "Completed today:`n$completed"
```

This example logs four hours of work against issue TEST-100 with a worklog comment that lists the issues the current user closed in the last day, formatted as a wiki-markup table.
A common pattern for end-of-day time tracking when several related tickets roll up into a single parent.

> Wiki-markup tables render natively on Jira **Server / Data Center**.
> On Jira **Cloud** use a Markdown table instead — the `||header||` wiki-markup syntax does not survive the Markdown → ADF conversion and renders as literal text.

### EXAMPLE 5

```powershell
$comment = Get-Process | ConvertTo-JiraTable
Add-JiraIssueWorklog $comment -Issue TEST-003 -TimeSpent 60 -DateStarted (Get-Date)
```

`ConvertTo-JiraTable` accepts any `PSObject` pipeline, so non-Jira data — here, the local process list — can also be tabulated and stored on a worklog comment.

## PARAMETERS

### -Comment

Worklog item that should be added to JIRA

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
  Position: 5
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -DateStarted

Date/time started to be logged

```yaml
Type: DateTime
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 3
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Issue

Issue to receive the new worklog item.

Can be a `JiraPS.Issue` object, issue key, or internal issue ID.

```yaml
Type: Object
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

### -TimeSpent

Time spent to be logged

```yaml
Type: TimeSpan
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 2
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
  Position: 4
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

### JiraPS.Issue

Pipe a JiraPS.Issue object to record work against it.

## OUTPUTS

### JiraPS.Worklogitem

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraIssueWorklog](../Get-JiraIssueWorklog)

[Get-JiraIssue](../Get-JiraIssue/)

[ConvertTo-JiraTable](../ConvertTo-JiraTable/)
