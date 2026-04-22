---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueAttachmentFile/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueAttachmentFile/
---
# Get-JiraIssueAttachmentFile

## SYNOPSIS

Save an attachment to disk.

## SYNTAX

```powershell
Get-JiraIssueAttachmentFile [-Attachment] <Attachment> [[-Path] <string>]
 [[-Credential] <pscredential>] [<CommonParameters>]
```

## DESCRIPTION

This function downloads an attachment of an issue to the local disk.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraIssueAttachmentFile (Get-JiraIssueAttachment -Issue TEST-001)
```

This example downloads all attachments from issue TEST-001 to the current
working directory.

### EXAMPLE 2

```powershell
Get-JiraIssue TEST-002 | Get-JiraIssueAttachment | Get-JiraIssueAttachmentFile
```

This example illustrates use of the pipeline to download all attachments from
issue TEST-002.

### EXAMPLE 3

```powershell
Get-JiraIssue TEST-002 |
    Get-JiraIssueAttachment -FileName "*.png" |
    Get-JiraIssueAttachmentFile -Path "c:\temp
```

Download all attachments of issue TEST-002 where the filename ends in `.png`
to a specific location.

## PARAMETERS

### -Attachment

Attachment which will be downloaded.

```yaml
Type: JiraPS.Attachment
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
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

### -Path

Path in which to store to attachment.

The name of the file will be appended to the Path provided.

```yaml
Type: System.String
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### JiraPS.Attachment

## OUTPUTS

### Bool


### System.Boolean

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraAttachment](../Get-JiraAttachmentFile/)

[Add-JiraIssueAttachmentFile](../Add-JiraIssueAttachmentFile/)

[Get-JiraIssue](../Get-JiraIssue/)

[Remove-JiraIssueAttachmentFile](../Remove-JiraIssueAttachmentFile/)
