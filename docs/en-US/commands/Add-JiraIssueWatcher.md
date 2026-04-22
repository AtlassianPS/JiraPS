---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Add-JiraIssueWatcher/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Add-JiraIssueWatcher/
---
# Add-JiraIssueWatcher

## SYNOPSIS

Adds a watcher to an existing JIRA issue

## SYNTAX

```powershell
Add-JiraIssueWatcher [-Watcher] <string[]> [-Issue] <Object> [[-Credential] <pscredential>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function adds a watcher to an existing issue in JIRA.

## EXAMPLES

### EXAMPLE 1

```powershell
Add-JiraIssueWatcher -Watcher "fred" -Issue "TEST-001"
```

This example adds a watcher to the issue TEST-001.

### EXAMPLE 2

```powershell
Get-JiraIssue "TEST-002" | Add-JiraIssueWatcher "fred"
```

This example illustrates pipeline use from `Get-JiraIssue` to `Add-JiraIssueWatcher`.

### EXAMPLE 3

```powershell
Get-JiraIssue -Query 'project = "TEST" AND created >= -5d' |
    Add-JiraIssueWatcher "fred"
```

This example illustrates adding watcher on all projects which match a given JQL query.
It would be best to validate the query first to make sure the query returns the expected issues!

## PARAMETERS

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
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Issue

Issue that should be watched.

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

### -Watcher

Watcher that should be added to JIRA

```yaml
Type: String[]
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

Pipe a JiraPS.Issue object to add a watcher to it.

## OUTPUTS

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraIssue](../Get-JiraIssue/)

[Get-JiraUser](../Get-JiraUser/)

[Get-JiraIssueWatcher](../Get-JiraIssueWatcher/)

[Remove-JiraIssueWatcher](../Remove-JiraIssueWatcher/)
