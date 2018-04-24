---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Add-JiraIssueAttachment/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Add-JiraIssueAttachment/
---
# Add-JiraIssueAttachment

## SYNOPSIS

Adds a file attachment to an existing Jira Issue

## SYNTAX

```powershell
Add-JiraIssueAttachment [-Issue] <Object> [-FilePath] <String[]> [[-Credential] <PSCredential>] [-PassThru]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function adds an Attachment to an existing issue in JIRA.

## EXAMPLES

### EXAMPLE 1

```powershell
Add-JiraIssueAttachment -FilePath "Test comment" -Issue "TEST-001"
```

This example adds a simple comment to the issue TEST-001.

### EXAMPLE 2

```powershell
Get-JiraIssue "TEST-002" | Add-JiraIssueAttachment -FilePath "Test comment from PowerShell"
```

This example illustrates pipeline use from Get-JiraIssue to Add-JiraIssueAttachment.

## PARAMETERS

### -Issue

Issue to which to attach the file.

Can be a `JiraPS.Issue` object, issue key, or internal issue ID.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: Key

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilePath

Path of the file to upload and attach

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: InFile, FullName, Path

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru

Whether output should be provided after invoking this function

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

### This function can accept JiraPS.Issue objects via pipeline.

## OUTPUTS

### [JiraPS.Attachment]

This function outputs the results of the attachment add.

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraIssueAttachment](../Get-JiraIssueAttachment/)

[Remove-JiraIssueAttachment](../Remove-JiraIssueAttachment/)
