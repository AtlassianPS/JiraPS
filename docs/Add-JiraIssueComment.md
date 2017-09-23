---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Add-JiraIssueComment

## SYNOPSIS
Adds a comment to an existing JIRA issue

## SYNTAX

```
Add-JiraIssueComment [-Comment] <String> [-Issue] <Object> [-VisibleRole <String>] [-Credential <PSCredential>]
```

## DESCRIPTION
This function adds a comment to an existing issue in JIRA.
You can optionally set the visibility of the comment (All Users, Developers, or Administrators).

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Add-JiraIssueComment -Comment "Test comment" -Issue "TEST-001"
```

This example adds a simple comment to the issue TEST-001.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-JiraIssue "TEST-002" | Add-JiraIssueComment "Test comment from PowerShell"
```

This example illustrates pipeline use from Get-JiraIssue to Add-JiraIssueComment.

### -------------------------- EXAMPLE 3 --------------------------
```
= -5d' | % { Add-JiraIssueComment "This issue has been cancelled per Vice President's orders." }
```

This example illustrates commenting on all projects which match a given JQL query.
It would be best to validate the query first to make sure the query returns the expected issues!

### -------------------------- EXAMPLE 4 --------------------------
```
$comment = Get-Process | Format-Jira
```

Add-JiraIssueComment $c -Issue TEST-003
This example illustrates adding a comment based on other logic to a JIRA issue. 
Note the use of Format-Jira to convert the output of Get-Process into a format that is easily read by users.

## PARAMETERS

### -Comment
Comment that should be added to JIRA.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Issue
Issue that should be commented upon.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: Key

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -VisibleRole
Visibility of the comment - should it be publicly visible, viewable to only developers, or only administrators?

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: Developers
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
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### This function can accept JiraPS.Issue objects via pipeline.

## OUTPUTS

### This function outputs the JiraPS.Comment object created.

## NOTES
This function requires either the -Credential parameter to be passed or a persistent JIRA session.
See New-JiraSession for more details. 
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

