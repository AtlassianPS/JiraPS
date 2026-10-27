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

Adds a worklog item to an existing Jira issue.

## SYNTAX

```powershell
Add-JiraIssueWorklog -Comment <String> -Issue <AtlassianPS.JiraPS.Issue> -TimeSpent <TimeSpan> -DateStarted <DateTime> [-Visibility <AtlassianPS.JiraPS.Visibility>] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

## DESCRIPTION

This function adds a worklog item to an existing issue in Jira.
You can optionally set the visibility of the item (All users, Developers, or Administrators).

On **Jira Cloud**, the `-Comment` text is interpreted as Markdown and converted to Atlassian Document Format (ADF) before being sent.
The reverse path is also handled: when worklogs are read back from Cloud, the ADF comment payload is rendered to plain text on the returned `AtlassianPS.JiraPS.Worklogitem` object.
On **Jira Server / Data Center**, the comment is sent and read back verbatim and the legacy wiki-markup syntax continues to apply.
See [`ConvertTo-AtlassianDocumentFormat`](../ConvertTo-AtlassianDocumentFormat/) for the supported Markdown subset.

## EXAMPLES

### Example 1

```powershell
Add-JiraIssueWorklog -Comment 'Test comment' -Issue 'TEST-001' -TimeSpent 60 -DateStarted (Get-Date)
```

This example adds a simple worklog item to the issue TEST-001.

### Example 2

```powershell
Get-JiraIssue 'TEST-002' | Add-JiraIssueWorklog 'Test worklog item from PowerShell' -TimeSpent 60 -DateStarted (Get-Date)
```

This example illustrates pipeline use from `Get-JiraIssue` to `Add-JiraIssueWorklog`.

### Example 3

```powershell
Get-JiraIssue -Query 'project = "TEST" AND created >= -5d' |
    Add-JiraIssueWorklog "This issue has been cancelled per Vice President's orders." -TimeSpent 60 -DateStarted (Get-Date)
```

This example illustrates logging work on all projects which match a given JQL query.
It would be best to validate the query first to make sure the query returns the expected issues!

### Example 4

```powershell
$completed = Get-JiraIssue -Query 'project = TEST AND assignee = currentUser() AND status = Done AND updated >= -1d' |
    ConvertTo-JiraTable -Property Key, Summary
Add-JiraIssueWorklog -Issue TEST-100 -TimeSpent 14400 -DateStarted (Get-Date) -Comment "Completed today:`n$completed"
```

This example logs four hours of work against issue TEST-100 with a worklog comment that lists the issues the current user closed in the last day, formatted as a wiki-markup table.
A common pattern for end-of-day time tracking when several related tickets roll up into a single parent.

> Wiki-markup tables render natively on Jira **Server / Data Center**.
> On Jira **Cloud** use a Markdown table instead — the `||header||` wiki-markup syntax does not survive the Markdown → ADF conversion and renders as literal text.

### Example 5

```powershell
$comment = Get-Process | ConvertTo-JiraTable
Add-JiraIssueWorklog $comment -Issue TEST-003 -TimeSpent 60 -DateStarted (Get-Date)
```

`ConvertTo-JiraTable` accepts any `PSObject` pipeline, so non-Jira data — here, the local process list — can also be tabulated and stored on a worklog comment.

## PARAMETERS

### -Comment

Worklog item that should be added to Jira.

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

Username/password or compatible Cloud email/token as PSCredential.
Explicit input temporarily overrides the selected identity without inheriting cookies or changing the stored connection.
An empty credential fails; omitted input uses the selected connection.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DateStarted

Date/time started to be logged.

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

Can be an `AtlassianPS.JiraPS.Issue` object, issue key, or internal issue ID.

```yaml
Type: AtlassianPS.JiraPS.Issue
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

Time spent to be logged.

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

### -Visibility

Restricts access to a role or group using an `AtlassianPS.JiraPS.Visibility` object.
Omit this parameter for unrestricted access.
String values remain supported through both `Visibility` and its `VisibleRole` alias:

- `All Users` leaves access unrestricted.
- `Developers` restricts access to that project role.
- `Administrators` restricts access to that project role.

Other project role names are also accepted; the role must exist in Jira.
Use `@{ Type = 'group'; Value = 'jira-users' }` for a group, or supply its `Identifier` where supported by Jira.
Group restrictions require Jira's **Comment visibility** setting to allow **groups & project Roles**.
On Cloud, an administrator can set this under **Settings > System > General Configuration**.
A role visibility object with `Value = 'All Users'` and no `Identifier` also leaves access unrestricted.
Unrestricted access omits the REST `visibility` property; it does not send an `All Users` role to Jira.
`VisibleRole` remains an alias.

```yaml
Type: AtlassianPS.JiraPS.Visibility
DefaultValue: ''
SupportsWildcards: false
Aliases:
- VisibleRole
ParameterSets:
- Name: (All)
  Position: 4
  IsRequired: false
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

### -Connection

Active Jira connection for this operation.
Session is a compatibility alias.
When omitted, the command uses the selected Jira default.
Use Get-JiraConnection -Name to resolve a named connection.

```yaml
Type: AtlassianPS.Connection
Parameter Sets: (All)
Aliases: Session

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable.
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.Issue

Pipe an AtlassianPS.JiraPS.Issue object to record work against it.

## OUTPUTS

### AtlassianPS.JiraPS.Worklogitem

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraIssueWorklog](../Get-JiraIssueWorklog)

[Get-JiraIssue](../Get-JiraIssue/)

[ConvertTo-JiraTable](../ConvertTo-JiraTable/)
