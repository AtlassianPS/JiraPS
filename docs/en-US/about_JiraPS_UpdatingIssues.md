---
locale: en-US
layout: documentation
online version: https://atlassianps.org/docs/JiraPS/about/updating-issues.html
Module Name: JiraPS
permalink: /docs/JiraPS/about/updating-issues.html
---
# Updating Issues

## about_JiraPS_UpdatingIssues

# SHORT DESCRIPTION

This page explains the mechanics for updating a Jira issue.

# LONG DESCRIPTION

Jira issues can be updated in 3 different ways:

- **Editing Issues**: change the value of fields (eg: changing the assignee)
- **Adding Comments**
- **Issue Transitions**: Moving the issue to a following status (eg: moving the issue to "In Work")

## Editing Issues

Editing issues is done with the `Set-JiraIssue` function.

```powershell
# Assign an issue
Set-JiraIssue TEST-1 -Assignee 'bob'

# Get the issue's existing summary and add a tag
$issue = Get-JiraIssue TEST-1
$issue | Set-JiraIssue -Summary "$($issue.Summary) (Modified by PowerShell)"

# Change the issue's summary and add a comment for that change
$issue | Set-JiraIssue -Summary "New Summary" -AddComment "Changed summary for testing"
```

If the field you want to change does not have a named parameter, `Set-JiraIssue` also supports changing arbitrary fields using the `-Fields` parameter.
For more information on this parameter, see the [custom_fields](https://atlassianps.org/docs/JiraPS/About/custom-fields.html) page.

### Labels

You can set labels on an issue using `Set-JiraIssue`'s `-Label` parameter.
Using this function will overwrite any existing labels on the issue.
`-SkipNotification` parameter tells JIRA to not update users abouth the change. Default behaviour is always send notifications.

```powershell
Get-JiraIssue TEST-1 | Set-JiraIssue -Label 'Funny','Testing' -SkipNotification
```

For better control over labels, use `Set-JiraIssueLabel`.
This provides more granular control over the labels in an issue using four parameters:

- **Add** adds labels to an issue without modifying any existing labels.
- **Remove** removes specific labels from an issue.
- **Set** overwrites all labels with any labels passed to this parameter.
- **Clear** removes all labels from the issue.

The `-Add` and `-Remove` parameters can be used together; `-Set` and `-Clear` must be used individually.

```powershell
$issue = Get-JiraIssue TEST-1

# Overwrite all labels with these two
$issue | Set-JiraIssueLabel -Set 'Funny','Test'

# Add another label and remove the Funny label - after this, the
# issue will have 'Test' and 'Serious'
$issue | Set-JiraIssueLabel -Add 'Serious' -Remove 'Funny'

# Remove ALL the labels!
$issue | Set-JiraIssueLabel -Clear
```

## Adding Comments

`Add-JiraIssueComment` is your friend here.

```powershell
Add-JiraIssueComment -Issue TEST-1 -Comment "Test comment from PowerShell"
```

You can also use `Format-Jira` to convert a PowerShell object into a Jira table.

```powershell
$commentText = Get-Process powershell | Format-Jira
Get-JiraIssue TEST-1 | Add-JiraIssueComment "Current PowerShell processes:\n$commentText"
```

> Like other `Format-*` commands, `Format-Jira` is a destructive operation for data in the pipeline.
> Remember to "filter left, format right!"

Comments can also be added while changing other fields of issues, e.g. the assignee:

```powershell
Set-JiraIssue -Issue TEST-1 -Assignee "John" -Addcomment "Dear mr. Doe, please review this issue.Thx"
```

## Issue Transitions

Closing an issue, reopening an issue, or changing an issue to a pending state are all examples of what Jira calls "issue transitions."
The transitions an issue can perform depend on its current status and the Jira workflow set up for its project.

First, check the transitions an issue can currently perform:

```powershell
(Get-JiraIssue TEST-1).Transition
```

Once you have a list of transitions, use `Invoke-JiraIssueTransition` with the ID of the transition to perform:

```powershell
Get-JiraIssue TEST-1 | Invoke-JiraIssueTransition -Transition 11
```

> For more information on configuring transitions in JIRA, see Atlassian's article on [JIRA Workflows](https://confluence.atlassian.com/adminjiraserver072/working-with-workflows-828787890.html).

# KEYWORDS

- workflow
- comments
- update
- transition
