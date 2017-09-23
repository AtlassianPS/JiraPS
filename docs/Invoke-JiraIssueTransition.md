---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Invoke-JiraIssueTransition

## SYNOPSIS
Performs an issue transition on a JIRA issue, changing its status

## SYNTAX

```
Invoke-JiraIssueTransition [-Issue] <Object> [-Transition] <Object> [-Fields <Hashtable>] [-Assignee <Object>]
 [-Comment <String>] [-Credential <PSCredential>]
```

## DESCRIPTION
This function performs an issue transition on a JIRA issue. 
Transitions are
defined in JIRA through workflows, and allow the issue to move from one status
to the next. 
For example, the "Start Progress" transition typically moves
an issue from an Open status to an "In Progress" status.

To identify the transitions that an issue can perform, use Get-JiraIssue and
check the Transition property of the issue object returned. 
Attempting to
perform a transition that does not apply to the issue (for example, trying
to "start progress" on an issue in progress) will result in an exception.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11
```

Invokes transition ID 11 on issue TEST-01.

### -------------------------- EXAMPLE 2 --------------------------
```
Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Comment 'Transition comment'
```

Invokes transition ID 11 on issue TEST-01 with a comment.
Requires the comment field to be configured visible for transition.

### -------------------------- EXAMPLE 3 --------------------------
```
Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Assignee 'joe.bloggs'
```

Invokes transition ID 11 on issue TEST-01 and assigns to user 'Joe Blogs'.
Requires the assignee field to be configured as visible for transition.

### -------------------------- EXAMPLE 4 --------------------------
```
$transitionFields = @{'customfield_12345' = 'example'}
```

Invoke-JiraIssueTransition -Issue TEST-01 -Transition 11 -Fields $transitionFields
Invokes transition ID 11 on issue TEST-01 and configures a custom field value.
Requires fields to be configured as visible for transition.

### -------------------------- EXAMPLE 5 --------------------------
```
$transition = Get-JiraIssue -Issue TEST-01 | Select-Object -ExpandProperty Transition | ? {$_.ResultStatus.Name -eq 'In Progress'}
```

Invoke-JiraIssueTransition -Issue TEST-01 -Transition $transition
This example identifies the correct transition based on the result status of
"In Progress," and invokes that transition on issue TEST-01.

## PARAMETERS

### -Issue
The Issue Object or ID to transition.

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
The Transition Object or ID.

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
Type: Hashtable
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Assignee
New assignee of the issue.
Enter 'Unassigned' to unassign the issue.
Assignee field must be configured to appear on the transition screen to use this parameter.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
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
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Credentials to use to connect to Jira

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### [JiraPS.Issue] Issue (can also be provided as a String)
[JiraPS.Transition] Transition to perform (can also be provided as an int ID)

## OUTPUTS

### This function does not provide output.

## NOTES

## RELATED LINKS

