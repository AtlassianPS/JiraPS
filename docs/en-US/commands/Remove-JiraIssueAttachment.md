---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraIssueAttachment/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Remove-JiraIssueAttachment/
---
# Remove-JiraIssueAttachment

## SYNOPSIS

Removes an attachment from a JIRA issue

## SYNTAX

### byId (Default)

```powershell
Remove-JiraIssueAttachment [-AttachmentId] <Int32[]> [-Session <PSObject>] [-Force] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### byIssue

```powershell
Remove-JiraIssueAttachment [-Issue] <Object> [-FileName <String[]>] [-Session <PSObject>] [-Force]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function removes an attachment from a JIRA issue.

## EXAMPLES

### EXAMPLE 1

```powershell
Remove-JiraIssueAttachment -AttachmentId 10039
```

Removes attachment with id of 10039

### EXAMPLE 2

```powershell
Get-JiraIssueAttachment -Issue FOO-1234 | Remove-JiraIssueAttachment
```

Removes all attachments from issue FOO-1234

### EXAMPLE 3

```powershell
Remove-JiraIssueAttachment -Issue FOO-1234 -FileName '*.png' -force
```

Removes all *.png attachments from Issue FOO-1234 without prompting for confirmation

## PARAMETERS

### -AttachmentId

Id of the Attachment to delete

```yaml
Type: Int32[]
Parameter Sets: byId
Aliases: Id

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Issue

Issue from which to delete on or more attachments.

Can be a `JiraPS.Issue` object, issue key, or internal issue ID.

```yaml
Type: Object
Parameter Sets: byIssue
Aliases: Key

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FileName

Name of the File to delete

```yaml
Type: String[]
Parameter Sets: byIssue
Aliases:

Required: False
Position: Named
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
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force

Suppress user confirmation.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [JiraPS.Issue] / [String] / [Int]

## OUTPUTS

## NOTES

This function requires either the `-Session` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Add-JiraIssueAttachment](../Add-JiraIssueAttachment/)

[Get-JiraIssue](../Get-JiraIssue/)

[Get-JiraIssueAttachment](../Get-JiraIssueAttachment/)
