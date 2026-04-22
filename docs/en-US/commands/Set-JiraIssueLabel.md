---
document type: cmdlet
external help file: JiraPS-help.xml
HelpUri: https://atlassianps.org/docs/JiraPS/commands/Set-JiraIssueLabel/
Locale: en-DE
Module Name: JiraPS
ms.date: 04.22.2026
PlatyPS schema version: 2024-05-01
title: Set-JiraIssueLabel
---

# Set-JiraIssueLabel

## SYNOPSIS

Modifies labels on an existing JIRA issue

## SYNTAX

### ReplaceLabels (Default)

```
Set-JiraIssueLabel [-Issue] <Object[]> -Set <string[]> [-Credential <pscredential>] [-PassThru]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ModifyLabels

```
Set-JiraIssueLabel [-Issue] <Object[]> [-Add <string[]>] [-Remove <string[]>]
 [-Credential <pscredential>] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ClearLabels

```
Set-JiraIssueLabel [-Issue] <Object[]> -Clear [-Credential <pscredential>] [-PassThru] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function modifies labels on an existing JIRA issue.
There are four supported operations on labels:

- **Add**: appends additional labels to the labels that an issue already has - **Remove**: Removes labels from an issue's current labels - **Set**: erases the existing labels on the issue and replaces them with the provided values - **Clear**: removes all labels from the issue

## EXAMPLES

### EXAMPLE 1

Set-JiraIssueLabel -Issue TEST-01 -Set 'fixed'


This example replaces all existing labels on issue TEST-01 with one label, "fixed".

### EXAMPLE 2

Get-JiraIssue -Query 'created >= -7d AND reporter in (joeSmith)' | Set-JiraIssueLabel -Add 'enhancement'


This example adds the "enhancement" label to all issues matching the JQL - in this case,
all issues created by user joeSmith in the last 7 days.

### EXAMPLE 3

Get-JiraIssue TEST-01 | Set-JiraIssueLabel -Clear


This example removes all labels from the issue TEST-01.

## PARAMETERS

### -Add

Labels to be added in addition to the existing ones.

```yaml
Type: System.String[]
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
Type: System.Management.Automation.SwitchParameter
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
Type: System.Management.Automation.SwitchParameter
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
Type: System.Management.Automation.PSCredential
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

### -Issue

Issue of which the labels should be manipulated.

Can be a `JiraPS.Issue` object, issue key, or internal issue ID.

```yaml
Type: System.Object[]
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
Type: System.Management.Automation.SwitchParameter
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
Type: System.String[]
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
Type: System.String[]
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
Type: System.Management.Automation.SwitchParameter
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

### JiraPS.Issue

{{ Fill in the Description }}

### System.Object[]

{{ Fill in the Description }}

## OUTPUTS

### JiraPS.Issue

If the `-PassThru` parameter is provided, this function will provide a reference
to the JIRA issue modified.
 Otherwise, this function does not provide output.

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.


## RELATED LINKS

- [Online Version](https://atlassianps.org/docs/JiraPS/commands/Set-JiraIssueLabel/)
- [Get-JiraIssue](../Get-JiraIssue/)
