---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueWatcher/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueWatcher/
---
# Get-JiraIssueWatcher

## SYNOPSIS

Returns watchers on an issue in JIRA.

## SYNTAX

```powershell
Get-JiraIssueWatcher [-Issue] <Object> [[-Credential] <pscredential>] [<CommonParameters>]
```

## DESCRIPTION

This function obtains watchers from existing issues in JIRA.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraIssueWatcher -Key TEST-001
```

This example returns all watchers posted to issue TEST-001.

### EXAMPLE 2

```powershell
Get-JiraIssue TEST-002 | Get-JiraIssueWatcher
```

This example illustrates use of the pipeline to return all watchers on issue TEST-002.

## PARAMETERS

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
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Issue

JIRA issue to check for watchers.

Can be a `JiraPS.Issue` object, issue key, or internal issue ID.

```yaml
Type: Object
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Key
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
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

### JiraPS.Issue / String

## OUTPUTS

### JiraPS.User

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Add-JiraIssueWatcher](../Add-JiraIssueWatcher/)

[Remove-JiraIssueWatcher](../Remove-JiraIssueWatcher/)
