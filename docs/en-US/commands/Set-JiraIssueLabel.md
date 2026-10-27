---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Set-JiraIssueLabel/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Set-JiraIssueLabel/
---
# Set-JiraIssueLabel

## SYNOPSIS

Modifies labels on an existing Jira issue.

## SYNTAX

### ReplaceLabels (Default)

```powershell
Set-JiraIssueLabel -Issue <AtlassianPS.JiraPS.Issue> -Set <String[]> [-Credential <PSCredential>] [-PassThru] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

### ModifyLabels

```powershell
Set-JiraIssueLabel -Issue <AtlassianPS.JiraPS.Issue> [-Add <String[]>] [-Remove <String[]>] [-Credential <PSCredential>] [-PassThru] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

### ClearLabels

```powershell
Set-JiraIssueLabel -Issue <AtlassianPS.JiraPS.Issue> -Clear [-Credential <PSCredential>] [-PassThru] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

## DESCRIPTION

This function modifies labels on an existing Jira issue.
There are four supported operations on labels:

- **Add**: appends additional labels to the labels that an issue already has
- **Remove**: Removes labels from an issue's current labels
- **Set**: erases the existing labels on the issue and replaces them with the provided values
- **Clear**: removes all labels from the issue

## EXAMPLES

### Example 1

```powershell
Set-JiraIssueLabel -Issue TEST-01 -Set 'fixed'
```

This example replaces all existing labels on issue TEST-01 with one label, "fixed".

### Example 2

```powershell
Get-JiraIssue -Query 'created >= -7d AND reporter in (joeSmith)' | Set-JiraIssueLabel -Add 'enhancement'
```

This example adds the "enhancement" label to all issues matching the JQL - in this case, all issues created by user joeSmith in the last 7 days.

### Example 3

```powershell
Get-JiraIssue TEST-01 | Set-JiraIssueLabel -Clear
```

This example removes all labels from the issue TEST-01.

## PARAMETERS

### -Add

Labels to be added in addition to the existing ones.

```yaml
Type: String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ModifyLabels
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Clear

Remove all labels of the issue.

```yaml
Type: SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ClearLabels
  Position: Named
  IsRequired: true
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

Username/password or compatible Cloud email/token as PSCredential.
Explicit input temporarily overrides the selected identity without inheriting cookies or changing the stored connection.
An empty credential fails; omitted input uses the selected connection.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Issue

Issue of which the labels should be manipulated.

Can be an `AtlassianPS.JiraPS.Issue` object, issue key, or internal issue ID.

```yaml
Type: AtlassianPS.JiraPS.Issue
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

### -Remove

Labels of the issue to be removed.

```yaml
Type: String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ModifyLabels
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Set

List of labels that will be set to the issue.

Any label that was already assigned to the issue will be removed.

```yaml
Type: String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Label
- Replace
ParameterSets:
- Name: ReplaceLabels
  Position: Named
  IsRequired: true
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

### -Connection

Active Jira connection for this operation.
Session is a compatibility alias.
When omitted, the command uses the selected Jira default.
Use Get-JiraConnection -Name to resolve a named connection.

```yaml
Type: AtlassianPS.Connection
Parameter Sets: (All)
Aliases: Session

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable.
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.Issue


## OUTPUTS

### AtlassianPS.JiraPS.Issue

If the `-PassThru` parameter is provided, this function will provide a reference to the Jira issue modified.
Otherwise, this function does not provide output.

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraIssue](../Get-JiraIssue/)
