---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Set-JiraIssue/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Set-JiraIssue/
---
# Set-JiraIssue

## SYNOPSIS

Modifies an existing issue in JIRA

## SYNTAX

### AssignToUser (Default)

```powershell
Set-JiraIssue -Issue <Object[]> [-Summary <string>] [-Description <string>] [-FixVersion <string[]>]
 [-Assignee <Object>] [-Label <string[]>] [-Fields <psobject>] [-AddComment <string>]
 [-Credential <pscredential>] [-PassThru] [-SkipNotification] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Unassign

```powershell
Set-JiraIssue -Issue <Object[]> [-Summary <string>] [-Description <string>] [-FixVersion <string[]>]
 [-Unassign] [-Label <string[]>] [-Fields <psobject>] [-AddComment <string>]
 [-Credential <pscredential>] [-PassThru] [-SkipNotification] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### UseDefaultAssignee

```powershell
Set-JiraIssue -Issue <Object[]> [-Summary <string>] [-Description <string>] [-FixVersion <string[]>]
 [-UseDefaultAssignee] [-Label <string[]>] [-Fields <psobject>] [-AddComment <string>]
 [-Credential <pscredential>] [-PassThru] [-SkipNotification] [-WhatIf] [-Confirm]
 [<CommonParameters>]
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
Set-JiraIssue -Issue TEST-01 -Unassign
```

This example removes the assignee from JIRA issue TEST-01.

### EXAMPLE 4

```powershell
Set-JiraIssue -Issue TEST-01 -UseDefaultAssignee
```

This example sets the assignee of JIRA issue TEST-01 to the project's default assignee.

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

### -AddComment

Add a comment to the issue along with other changes.

```yaml
Type: String
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

### -Assignee

New assignee of the issue.

Use `-Unassign` to remove the assignee.
Use `-UseDefaultAssignee` to set the project's default assignee.

Empty strings and `$null` values are not accepted.

```yaml
Type: Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AssignToUser
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
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
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Description

New description of the issue.

```yaml
Type: String
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

### -Fields

Any additional fields that should be updated.

Inspect [about_JiraPS_CustomFields](../../about/custom-fields.html) for more information.

```yaml
Type: PSObject
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

### -FixVersion

Set the FixVersion of the issue, this will overwrite any present FixVersions

```yaml
Type: String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- FixVersions
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

### -Issue

Issue to be changed.

Can be a `JiraPS.Issue` object, issue key, or internal issue ID.

```yaml
Type: Object[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Key
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Label

Labels to be set on the issue.

These will overwrite any existing labels on the issue.

For more granular control over issue labels, use `Set-JiraIssueLabel`.

```yaml
Type: String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Labels
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

### -PassThru

Whether output should be provided after invoking this function.

```yaml
Type: SwitchParameter
DefaultValue: False
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

### -SkipNotification

Whether send notification to users about issue change or not

```yaml
Type: SwitchParameter
DefaultValue: False
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

### -Summary

New summary of the issue.

```yaml
Type: String
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

### -Unassign

Remove the current assignee of the issue.

```yaml
Type: SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Unassign
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -UseDefaultAssignee

Set the issue's assignee to the project's default assignee.

This is useful when you want Jira to automatically determine the assignee
based on the project's configuration.

```yaml
Type: SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: UseDefaultAssignee
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

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

### JiraPS.Issue / String / Int

## OUTPUTS

### JiraPS.Issue

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
