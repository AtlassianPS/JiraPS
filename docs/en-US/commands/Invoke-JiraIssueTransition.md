---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Invoke-JiraIssueTransition/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Invoke-JiraIssueTransition/
---
# Invoke-JiraIssueTransition

## SYNOPSIS

Changes an issue's status by performing a Jira transition.

## SYNTAX

### AssignToUser (Default)

```powershell
Invoke-JiraIssueTransition -Issue <AtlassianPS.JiraPS.Issue> -Transition <AtlassianPS.JiraPS.Transition> [-Fields <psobject>]
 [-Assignee <AtlassianPS.JiraPS.User>] [-Comment <string>] [-TimeSpent <timespan>] [-Passthru]
 [-Connection <AtlassianPS.Connection>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Unassign

```powershell
Invoke-JiraIssueTransition -Issue <AtlassianPS.JiraPS.Issue> -Transition <AtlassianPS.JiraPS.Transition> [-Fields <psobject>] [-Unassign]
 [-Comment <string>] [-TimeSpent <timespan>] [-Passthru] [-Connection <AtlassianPS.Connection>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

This function performs an issue transition on a Jira issue.

Transitions are defined in Jira through workflows, and allow the issue to move from one status to the next.

For example, the "Start Progress" transition typically moves an issue from an Open status to an "In Progress" status.

To identify the transitions that an issue can perform, use `Get-JiraIssue` and check the returned issue's `Transition` property.
Attempting to perform a transition that does not apply to the issue (for example, trying to "start progress" on an issue in progress) will result in an exception.

On **Jira Cloud**, the `-Comment` text is interpreted as Markdown and converted to Atlassian Document Format (ADF) before being sent.
On **Jira Server / Data Center**, the comment is sent verbatim and the legacy wiki-markup syntax continues to apply.
See [`ConvertTo-AtlassianDocumentFormat`](../ConvertTo-AtlassianDocumentFormat/) for the supported Markdown subset.

## EXAMPLES

### Example 1

```powershell
Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11
```

Invokes transition ID 11 on issue TEST-01.

### Example 2

```powershell
Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Comment 'Transition comment' -TimeSpent ([TimeSpan]::FromMinutes(15))
```

Invokes transition ID 11 on issue TEST-01 with a comment and a 15-minute worklog.
Requires the comment and worklog fields to be configured visible for transition.

### Example 3

```powershell
Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Assignee 'joe.bloggs'
```

Invokes transition ID 11 on issue TEST-01 and assigns it to user 'joe.bloggs'.

Requires the assignee field to be configured as visible for transition.

### Example 4

```powershell
$transitionFields = @{'customfield_12345' = 'example'}
Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Fields $transitionFields
```

Invokes transition ID 11 on issue TEST-01 and configures a custom field value.

Requires fields to be configured as visible for transition.

### Example 5

```powershell
$transition = Get-JiraIssue -Key TEST-01 | Select-Object -ExpandProperty Transition |
    Where-Object { $_.ResultStatus.Name -eq 'In Progress' }
Invoke-JiraIssueTransition -Issue TEST-01 -Transition $transition
```

This example identifies the correct transition based on the result status of "In Progress" and invokes that transition on issue TEST-01.

## PARAMETERS

### -Assignee

New assignee of the issue.

Use `-Unassign` to remove the assignee.
Empty strings and `$null` values are not accepted.

Assignee field must be configured to appear on the transition screen to use this parameter.

```yaml
Type: AtlassianPS.JiraPS.User
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AssignToUser
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Comment

Comment that should be added to Jira.

Comment field must be configured to appear on the transition screen to use this parameter.

```yaml
Type: String
DefaultValue: ''
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

### -Fields

Any additional fields that should be updated.

When you provide field names in `-Fields`, JiraPS first resolves them against transition-screen metadata for the selected transition.
If a provided key is not present in that scoped metadata, JiraPS falls back to the global `Get-JiraField` catalogue.
Using scoped metadata first avoids ambiguous name matching when duplicate custom-field display names exist across projects.

Fields must be configured to appear on the transition screen to use this parameter.

On **Jira Cloud**, string values supplied for rich-text fields (`description`, `environment`, and custom textarea fields with schema type `doc`) are interpreted as Markdown and converted to Atlassian Document Format (ADF) before being sent, matching the behaviour of the explicit `-Comment` parameter.
Plain string fields, numeric fields, dates, etc. are forwarded as-is.
Hashtable / object values are also forwarded as-is — pass a pre-built ADF document if you need full control.
On **Jira Server / Data Center** the value is always forwarded verbatim.

```yaml
Type: PSObject
DefaultValue: ''
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
Type: AtlassianPS.JiraPS.Issue
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Key
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Passthru

Whether output should be provided after invoking this function.

```yaml
Type: SwitchParameter
DefaultValue: False
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

### -TimeSpent

Time spent to record as a worklog during the transition.
Durations are sent as explicit minutes so Jira's configured workday length does not change the recorded time.

The worklog field must be configured to appear on the transition screen to use this parameter.

```yaml
Type: TimeSpan
DefaultValue: ''
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

### -Transition

Transition object, numeric ID or unambiguous available transition name.

```yaml
Type: AtlassianPS.JiraPS.Transition
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Unassign

Remove the current assignee of the issue as part of the transition.

Assignee field must be configured to appear on the transition screen to use this parameter.

```yaml
Type: SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Unassign
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

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

## OUTPUTS

### AtlassianPS.JiraPS.Issue

When `-Passthru` is provided, the issue will be returned.

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[about_JiraPS_CustomFields](../../about/custom-fields.html)

[about_JiraPS_UpdatingIssues](../../about/updating-issues.html)

[Get-JiraIssue](../Get-JiraIssue/)
