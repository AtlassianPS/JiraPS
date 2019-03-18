---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Invoke-JiraIssueTransition/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Invoke-JiraIssueTransition/
---
# Invoke-JiraIssueTransition

## SYNOPSIS

Performs an issue transition on a JIRA issue changing it's status

## SYNTAX

```powershell
Invoke-JiraIssueTransition [-Issue] <Object> [-Transition] <Object> [[-Fields] <PSCustomObject>]
 [[-Assignee] <Object>] [[-Comment] <String>] [[-TimeSpent] <String>] [[-Credential] <PSCredential>] [-Passthru] [<CommonParameters>]
```

## DESCRIPTION

This function performs an issue transition on a JIRA issue.

Transitions are defined in JIRA through workflows,
and allow the issue to move from one status to the next.

For example, the "Start Progress" transition typically moves
an issue from an Open status to an "In Progress" status.

To identify the transitions that an issue can perform,
use `Get-JiraIssue` and check the Transition property of the issue obj ect returned.
Attempting to perform a transition that does not apply to the issue
(for example, trying to "start progress" on an issue in progress) will result in an exception.

## EXAMPLES

### EXAMPLE 1

```powershell
Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11
```

Invokes transition ID 11 on issue TEST-01.

### EXAMPLE 2

```powershell
Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Comment 'Transition comment' -TimeSpent "15m"
```

Invokes transition ID 11 on issue TEST-01 with a comment and time spent of 15m (can be any jira supported suffix, like 'h' for hours e.g.)
Requires the comment field to be configured visible for transition and time tracking enabled in JIRA preferences. 

### EXAMPLE 3

```powershell
Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Assignee 'joe.bloggs'
```

Invokes transition ID 11 on issue TEST-01 and assigns to user 'Joe Blogs'.

Requires the assignee field to be configured as visible for transition.

### EXAMPLE 4

```powershell
$transitionFields = @{'customfield_12345' = 'example'}
Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Fields $transitionFields
```

Invokes transition ID 11 on issue TEST-01 and configures a custom field value.

Requires fields to be configured as visible for transition.

### EXAMPLE 5

```powershell
$transition = Get-JiraIssue -Issue TEST-01 | Select-Object -ExpandProperty Transition | ? {$_.ResultStatus.Name -eq 'In Progress'}
Invoke-JiraIssueTransition -Issue TEST-01 -Transition $transition
```

This example identifies the correct transition based on the result status of
"In Progress" and invokes that transition on issue TEST-01.

## PARAMETERS

### -Issue

The Issue Object or ID to transition.

Can be a `JiraPS.Issue` object, issue key, or internal issue ID.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: Key

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Transition

The Transition Object or it's ID.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Fields

Any additional fields that should be updated.

Fields must be configured to appear on the transition screen to use this parameter.

```yaml
Type: PSCustomObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Assignee

New assignee of the issue.

Enter `Unassigned` to remove the assignee of the issue.
Assignee field must be configured to appear on the transition screen to use this parameter.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Comment

Comment that should be added to JIRA.

Comment field must be configured to appear on the transition screen to use this parameter.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

Credentials to use to connect to JIRA.
If not specified, this function will use anonymous access.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru

Whether output should be provided after invoking this function.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [JiraPS.Issue] / [String] / [JiraPS.Transition]

## OUTPUTS

### [JiraPS.Issue]

When `-Passthru` is provided, the issue will be returned.

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[about_JiraPS_CustomFields](../../about/custom-fields.html)

[about_JiraPS_UpdatingIssues](../../about/updating-issues.html)

[Get-JiraIssue](../Get-JiraIssue/)
