---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Add-JiraIssueLink/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Add-JiraIssueLink/
---
# Add-JiraIssueLink

## SYNOPSIS

Adds a link between two Issues on Jira

## SYNTAX

```powershell
Add-JiraIssueLink [-Issue] <Object[]> [-IssueLink] <Object[]> [[-Comment] <String>]
 [[-Credential] <PSCredential>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Creates a new link of the specified type between two Issue.

## EXAMPLES

### EXAMPLE 1

```powershell
$_issueLink = [PSCustomObject]@{
    outwardIssue = [PSCustomObject]@{key = "TEST-10"}
    type = [PSCustomObject]@{name = "Composition"}
}
Add-JiraIssueLink -Issue TEST-01 -IssueLink $_issueLink
```

Creates a link "is part of" between TEST-01 and TEST-10

## PARAMETERS

### -Issue

Issue which should be linked.

Can be a `JiraPS.Issue` object, issue key, or internal issue ID.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases: Key

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -IssueLink

Issue Link to be created.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Comment

Write a comment to the issue

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
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
Position: 4
Default value: None
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

### [JiraPS.Issue[]]

The JIRA issue that should be linked
The JIRA issue link that should be used

## OUTPUTS

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraIssue](../Get-JiraIssue/)

[Get-JiraIssueLink](../Get-JiraIssueLink/)

[Get-JiraIssueLinkType](../Get-JiraIssueLinkType/)

[Remove-JiraIssueLink](../Remove-JiraIssueLink/)
