---
document type: cmdlet
external help file: JiraPS-help.xml
HelpUri: https://atlassianps.org/docs/JiraPS/commands/Add-JiraIssueComment/
Locale: en-DE
Module Name: JiraPS
ms.date: 04.22.2026
PlatyPS schema version: 2024-05-01
title: Add-JiraIssueComment
---

# Add-JiraIssueComment

## SYNOPSIS

Adds a comment to an existing JIRA issue

## SYNTAX

### __AllParameterSets

```
Add-JiraIssueComment [-Comment] <string> [-Issue] <Object> [[-VisibleRole] <string>]
 [[-Credential] <pscredential>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function adds a comment to an existing issue in JIRA.
You can optionally set the visibility of the comment (All Users, Developers, or Administrators).

## EXAMPLES

### EXAMPLE 1

Add-JiraIssueComment -Comment "Test comment" -Issue "TEST-001"


This example adds a simple comment to the issue TEST-001.

### EXAMPLE 2

Get-JiraIssue "TEST-002" | Add-JiraIssueComment "Test comment from PowerShell"


This example illustrates pipeline use from `Get-JiraIssue` to `Add-JiraIssueComment`.

### EXAMPLE 3

Get-JiraIssue -Query 'project = "TEST" AND created >= -5d' |
    Add-JiraIssueComment "This issue has been cancelled per Vice President's orders."


This example illustrates commenting on all projects which match a given JQL query.
It would be best to validate the query first to make sure the query returns the expected issues!

### EXAMPLE 4

$comment = Get-Process | Format-Jira
Add-JiraIssueComment $comment -Issue TEST-003


This example illustrates adding a comment based on other logic to a JIRA issue.
Note the use of `Format-Jira` to convert the output of `Get-Process` into a format that is easily read by users.

## PARAMETERS

### -Comment

Comment that should be added to JIRA.

```yaml
Type: System.String
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
Type: System.Management.Automation.SwitchParameter
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
Type: System.Management.Automation.PSCredential
DefaultValue: ''
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

Can be a `JiraPS.Issue` object, issue key, or internal issue ID.

```yaml
Type: System.Object
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
Type: System.String
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
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: System.Management.Automation.SwitchParameter
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

### This function can accept JiraPS.Issue objects via pipeline.

{{ Fill in the Description }}

### System.Object

{{ Fill in the Description }}

## OUTPUTS

### JiraPS.Comment

{{ Fill in the Description }}

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.


## RELATED LINKS

- [Online Version](https://atlassianps.org/docs/JiraPS/commands/Add-JiraIssueComment/)
- [Get-JiraIssue](../Get-JiraIssue/)
- [Get-JiraIssueComment](../Get-JiraIssueComment/)
- [Format-Jira](../Format-Jira/)
