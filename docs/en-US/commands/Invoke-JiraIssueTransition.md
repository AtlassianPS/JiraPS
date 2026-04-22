---
document type: cmdlet
external help file: JiraPS-help.xml
HelpUri: https://atlassianps.org/docs/JiraPS/commands/Invoke-JiraIssueTransition/
Locale: en-DE
Module Name: JiraPS
ms.date: 04.22.2026
PlatyPS schema version: 2024-05-01
title: Invoke-JiraIssueTransition
---

# Invoke-JiraIssueTransition

## SYNOPSIS

Performs an issue transition on a JIRA issue changing it's status

## SYNTAX

### AssignToUser (Default)

```
Invoke-JiraIssueTransition -Issue <Object> -Transition <Object> [-Fields <psobject>]
 [-Assignee <Object>] [-Comment <string>] [-Credential <pscredential>] [-Passthru]
 [<CommonParameters>]
```

### Unassign

```
Invoke-JiraIssueTransition -Issue <Object> -Transition <Object> [-Fields <psobject>] [-Unassign]
 [-Comment <string>] [-Credential <pscredential>] [-Passthru] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function performs an issue transition on a JIRA issue.

Transitions are defined in JIRA through workflows, and allow the issue to move from one status to the next.

For example, the "Start Progress" transition typically moves an issue from an Open status to an "In Progress" status.

To identify the transitions that an issue can perform, use `Get-JiraIssue` and check the Transition property of the issue obj ect returned.
Attempting to perform a transition that does not apply to the issue (for example, trying to "start progress" on an issue in progress) will result in an exception.

## EXAMPLES

### EXAMPLE 1

Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11


Invokes transition ID 11 on issue TEST-01.

### EXAMPLE 2

Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Comment 'Transition comment'


Invokes transition ID 11 on issue TEST-01 with a comment.
Requires the comment field to be configured visible for transition.

### EXAMPLE 3

Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Assignee 'joe.bloggs'


Invokes transition ID 11 on issue TEST-01 and assigns to user 'Joe Blogs'.

Requires the assignee field to be configured as visible for transition.

### EXAMPLE 4

$transitionFields = @{'customfield_12345' = 'example'}
Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Fields $transitionFields


Invokes transition ID 11 on issue TEST-01 and configures a custom field value.

Requires fields to be configured as visible for transition.

### EXAMPLE 5

$transition = Get-JiraIssue -Issue TEST-01 | Select-Object -ExpandProperty Transition | ? {$_.ResultStatus.Name -eq 'In Progress'}
Invoke-JiraIssueTransition -Issue TEST-01 -Transition $transition


This example identifies the correct transition based on the result status of
"In Progress" and invokes that transition on issue TEST-01.

## PARAMETERS

### -Assignee

New assignee of the issue.

Use `-Unassign` to remove the assignee.
Empty strings and `$null` values are not accepted.

Assignee field must be configured to appear on the transition screen to use this parameter.

```yaml
Type: System.Object
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

Comment that should be added to JIRA.

Comment field must be configured to appear on the transition screen to use this parameter.

```yaml
Type: System.String
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

### -Credential

Credentials to use to connect to JIRA.
If not specified, this function will use anonymous access.

```yaml
Type: System.Management.Automation.PSCredential
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

### -Fields

Any additional fields that should be updated.

Fields must be configured to appear on the transition screen to use this parameter.

```yaml
Type: System.Management.Automation.PSObject
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

The Issue Object or ID to transition.

Can be a `JiraPS.Issue` object, issue key, or internal issue ID.

```yaml
Type: System.Object
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
Type: System.Management.Automation.SwitchParameter
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

### -Transition

The Transition Object or it's ID.

```yaml
Type: System.Object
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
Type: System.Management.Automation.SwitchParameter
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### JiraPS.Issue / String / JiraPS.Transition

{{ Fill in the Description }}

### System.Object

{{ Fill in the Description }}

## OUTPUTS

### JiraPS.Issue

When `-Passthru` is provided, the issue will be returned.

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.


## RELATED LINKS

- [Online Version](https://atlassianps.org/docs/JiraPS/commands/Invoke-JiraIssueTransition/)
- [about_JiraPS_CustomFields](../../about/custom-fields.html)
- [about_JiraPS_UpdatingIssues](../../about/updating-issues.html)
- [Get-JiraIssue](../Get-JiraIssue/)
