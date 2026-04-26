---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueAttachment/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueAttachment/
---
# Get-JiraIssueAttachment

## SYNOPSIS

Returns attachments of an issue in JIRA.

## SYNTAX

```powershell
Get-JiraIssueAttachment [-Issue] <Issue> [[-FileName] <string>] [[-Credential] <pscredential>]
 [<CommonParameters>]
```

## DESCRIPTION

This function obtains attachments from existing issues in JIRA.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraIssueAttachment -Issue TEST-001
```

This example returns all attachments from issue TEST-001.

### EXAMPLE 2

```powershell
Get-JiraIssue TEST-002 | Get-JiraIssueAttachment
```

This example illustrates use of the pipeline to return all attachments from issue TEST-002.

### EXAMPLE 3

```powershell
Get-JiraIssue TEST-002 | Get-JiraIssueAttachment -FileName "*.png"
```

Returns all attachments of issue TEST-002 where the filename ends in `.png`

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
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -FileName

Name of the file(s) to filter.

This parameter supports wildcards.

```yaml
Type: String
DefaultValue: ''
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

JIRA issue to check for attachments.

Can be a `AtlassianPS.JiraPS.Issue` object, issue key, or internal issue ID.

```yaml
Type: Issue
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

### AtlassianPS.JiraPS.Issue / String

## OUTPUTS

### JiraPS.Attachment

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraAttachmentFile](../Get-JiraAttachmentFile/)

[Add-JiraIssueAttachment](../Add-JiraIssueAttachment/)

[Get-JiraIssue](../Get-JiraIssue/)

[Remove-JiraIssueAttachment](../Remove-JiraIssueAttachment/)
