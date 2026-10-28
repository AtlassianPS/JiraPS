---
document type: cmdlet
external help file: JiraPS-help.xml
HelpUri: https://atlassianps.org/docs/JiraPS/commands/Save-JiraIssueAttachment/
layout: documentation
locale: en-US
Module Name: JiraPS
ms.date: 10.28.2026
permalink: /docs/JiraPS/commands/Save-JiraIssueAttachment/
---

# Save-JiraIssueAttachment

## SYNOPSIS

Saves Jira attachment content to disk.

## SYNTAX

```powershell
Save-JiraIssueAttachment [-Attachment] <AtlassianPS.JiraPS.Attachment[]> [[-Path] <string>]
 [[-Connection] <AtlassianPS.Connection>] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Downloads attachment content to the file system and returns FileInfo for each completed write.
Directory destinations use the attachment file name.
Explicit file destinations accept one attachment.
Parent directories must exist, and Force is required to overwrite files.
WhatIf performs no download or file write.

## EXAMPLES

### Example 1

```powershell
Get-JiraIssueAttachment -Issue PROJ-1 | Save-JiraIssueAttachment -Path './downloads'
```

Save attachments into an existing directory and return FileInfo objects.

### Example 2

```powershell
$attachment | Save-JiraIssueAttachment -Path './report.bin' -Force
```

Save one attachment to a chosen file and overwrite it explicitly.

### Example 3

```powershell
$attachment | Save-JiraIssueAttachment -Path './report.bin' -WhatIf
```

Show the destination without downloading or writing the file.

## PARAMETERS

### -Attachment

Attachment metadata objects returned by Get-JiraIssueAttachment or Add-JiraIssueAttachment.

```yaml
Type: AtlassianPS.JiraPS.Attachment[]
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

### -Connection

Active Jira connection for this operation.
When omitted, the command uses the selected Jira default.
Create connections with Connect-Jira; resolve names with Get-JiraConnection -Name.

```yaml
Type: AtlassianPS.Connection
DefaultValue: ''
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

### -Force

Overwrite an existing destination file.
Confirmation is still controlled by Confirm.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases: []
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

### -Path

Existing destination directory, or an explicit destination file whose parent directory exists.
Defaults to the current directory.
A file destination accepts one attachment; multiple attachments require a directory.

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

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

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

### AtlassianPS.JiraPS.Attachment[]

## OUTPUTS

### System.IO.FileInfo

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

- [about_JiraPS_Authentication](../../about/authentication.html)
- [Get-JiraAttachment](../Save-JiraIssueAttachment/)
- [Add-JiraIssueAttachmentFile](../Add-JiraIssueAttachment/)
- [Get-JiraIssue](../Get-JiraIssue/)
- [Remove-JiraIssueAttachmentFile](../Remove-JiraIssueAttachment/)
