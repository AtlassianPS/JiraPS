---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Set-JiraIssueLabel/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Set-JiraIssueLabel/
---
# Set-JiraIssueLabel

## SYNOPSIS

Modifies labels on an existing JIRA issue

## SYNTAX

### ReplaceLabels (Default)

```powershell
Set-JiraIssueLabel [-Issue] <Object[]> -Set <String[]> [-Session <PSObject>] [-PassThru] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### ModifyLabels

```powershell
Set-JiraIssueLabel [-Issue] <Object[]> [-Add <String[]>] [-Remove <String[]>] [-Session <PSObject>]
 [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ClearLabels

```powershell
Set-JiraIssueLabel [-Issue] <Object[]> [-Clear] [-Session <PSObject>] [-PassThru] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

This function modifies labels on an existing JIRA issue.
There are four supported operations on labels:

- **Add**: appends additional labels to the labels that an issue already has
- **Remove**: Removes labels from an issue's current labels
- **Set**: erases the existing labels on the issue and replaces them with the provided values
- **Clear**: removes all labels from the issue

## EXAMPLES

### EXAMPLE 1

```powershell
Set-JiraIssueLabel -Issue TEST-01 -Set 'fixed'
```

This example replaces all existing labels on issue TEST-01 with one label, "fixed".

### EXAMPLE 2

```powershell
Get-JiraIssue -Query 'created >= -7d AND reporter in (joeSmith)' | Set-JiraIssueLabel -Add 'enhancement'
```

This example adds the "enhancement" label to all issues matching the JQL - in this case,
all issues created by user joeSmith in the last 7 days.

### EXAMPLE 3

```powershell
Get-JiraIssue TEST-01 | Set-JiraIssueLabel -Clear
```

This example removes all labels from the issue TEST-01.

## PARAMETERS

### -Issue

Issue of which the labels should be manipulated.

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

### -Set

List of labels that will be set to the issue.

Any label that was already assigned to the issue will be removed.

```yaml
Type: String[]
Parameter Sets: ReplaceLabels
Aliases: Label, Replace

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Add

Labels to be added in addition to the existing ones.

```yaml
Type: String[]
Parameter Sets: ModifyLabels
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Remove

Labels of the issue to be removed.

```yaml
Type: String[]
Parameter Sets: ModifyLabels
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Clear

Remove all labels of the issue.

```yaml
Type: SwitchParameter
Parameter Sets: ClearLabels
Aliases:

Required: True
Position: Named
Default value: False
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

### -PassThru

Whether output should be provided after invoking this function.

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

### [JiraPS.Issue]

## OUTPUTS

### [JiraPS.Issue]

If the `-PassThru` parameter is provided, this function will provide a reference
to the JIRA issue modified.  Otherwise, this function does not provide output.

## NOTES

This function requires either the `-Session` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraIssue](../Get-JiraIssue/)
