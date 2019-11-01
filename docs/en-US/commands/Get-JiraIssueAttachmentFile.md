---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueAttachmentFile/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueAttachmentFile/
---
# Get-JiraIssueAttachmentFile

## SYNOPSIS

Save an attachment to disk.

## SYNTAX

```powershell
Get-JiraIssueAttachmentFile [-Attachment] <JiraPS.Attachment> [[-Path] <String>]]
 [[-Session] <PSObject>] [<CommonParameters>]
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
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Path

Path in which to store to attachment.

The name of the file will be appended to the Path provided.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Session

Session to use to connect to JIRA.  
If not specified, this function will use default session.
The name of a session, PSCredential object or session's instance itself is accepted to pass as value for the parameter.

```yaml
Type: psobject
Parameter Sets: (All)
Aliases: Credential

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [JiraPS.Attachment]

## OUTPUTS

### [Bool]

## NOTES

This function requires either the `-Session` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraAttachment](../Get-JiraAttachmentFile/)

[Add-JiraIssueAttachmentFile](../Add-JiraIssueAttachmentFile/)

[Get-JiraIssue](../Get-JiraIssue/)

[Remove-JiraIssueAttachmentFile](../Remove-JiraIssueAttachmentFile/)
