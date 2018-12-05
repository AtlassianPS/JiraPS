---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Set-JiraIssue/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Set-JiraIssue/
---
# Set-JiraIssue

## SYNOPSIS

Modifies an existing issue in JIRA

## SYNTAX

```powershell
Set-JiraIssue [-Issue] <Object[]> [[-Summary] <String>] [[-Description] <String>] [[-FixVersion] <String[]>]
 [[-Assignee] <Object>] [[-Label] <String[]>] [[-Fields] <PSCustomObject>] [[-AddComment] <String>]
 [[-Credential] <PSCredential>] [-SkipNotification] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function modifies an existing issue in JIRA.
This can include changing the issue's summary or description, or assigning the issue.

## EXAMPLES

### EXAMPLE 1

```powershell
Set-JiraIssue -Issue TEST-01 -Summary 'Modified issue summary' -Description 'This issue has been modified by PowerShell' -SkipNotification
```

This example changes the summary and description of the JIRA issue TEST-01 without updating users by email about the change.

### EXAMPLE 2

```powershell
$issue = Get-JiraIssue TEST-01
$issue | Set-JiraIssue -Description "$($issue.Description)\`n\`nEdit: Also foo."
```

This example appends text to the end of an existing issue description by using
`Get-JiraIssue` to obtain a reference to the current issue and description.

### EXAMPLE 3

```powershell
Set-JiraIssue -Issue TEST-01 -Assignee 'Unassigned'
```

This example removes the assignee from JIRA issue TEST-01.

### EXAMPLE 4

```powershell
Set-JiraIssue -Issue TEST-01 -Assignee 'Default'
```

This example will set the assgignee of JIRA issue TEST-01 to the value the project or type of the issue determine as default.

### EXAMPLE 5

```powershell
Set-JiraIssue -Issue TEST-01 -Assignee 'joe' -AddComment 'Dear [~joe], please review.'
```

This example assigns the JIRA Issue TEST-01 to 'joe' and adds a comment at one.

### EXAMPLE 6

```powershell
$parameters = @{
    labels = @("DEPRECATED")
    AddComment = "Updated with a script"
    Fields = @{
        customfield_10000 = @(
            @{
                "value" = "NAME"
            }
        )
    }
}
Set-JiraIssue @parameters -Issue TEST-001, TEST-002
```

This example uses splatting to update "TEST-001" and "TEST-002".

You can read more about splatting in: about_Splatting

## PARAMETERS

### -Issue

Issue to be changed.

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

### -Summary

New summary of the issue.

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

### -Description

New description of the issue.

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

### -FixVersion

Set the FixVersion of the issue, this will overwrite any present FixVersions

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: FixVersions

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Assignee

New assignee of the issue.

Use the value `Unassigned` to remove the current assignee of the issue.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Label

Labels to be set on the issue.

These will overwrite any existing labels on the issue.

For more granular control over issue labels, use `Set-JiraIssueLabel`.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Fields

Any additional fields that should be updated.

Inspect [about_JiraPS_CustomFields](../../about/custom-fields.html) for more information.

```yaml
Type: PSCustomObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AddComment

Add a comment to the issue along with other changes.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
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
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipNotification

Whether send notification to users about issue change or not

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

### [JiraPS.Issue] / [String] / [Int]

## OUTPUTS

### [JiraPS.Issue]

If the `-PassThru` parameter is provided,
this function will provide a reference to the JIRA issue modified.
Otherwise, this function does not provide output.

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[about_JiraPS_UpdatingIssues](../../about/updating-issues.html)

[about_JiraPS_CustomFields](../../about/custom-fields.html)

[Get-JiraIssueEditMetadata](../Get-JiraIssueEditMetadata/)

[Get-JiraComponent](../Get-JiraComponent/)

[Get-JiraField](../Get-JiraField/)

[Get-JiraPriority](../Get-JiraPriority/)

[Get-JiraProject](../Get-JiraProject/)

[Get-JiraVersion](../Get-JiraVersion/)

[Set-JiraIssueLabel](../Set-JiraIssueLabel/)
