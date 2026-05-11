---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraIssueLink/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Remove-JiraIssueLink/
---
# Remove-JiraIssueLink

## SYNOPSIS

Removes a issue link from a JIRA issue

## SYNTAX

### ByIssueLink (Default)

```powershell
Remove-JiraIssueLink [-IssueLink] <IssueLink[]> [[-Credential] <pscredential>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### ByIssue

```powershell
Remove-JiraIssueLink [-Issue] <Issue[]> [[-Credential] <pscredential>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

This function removes a issue link from a JIRA issue.

## EXAMPLES

### EXAMPLE 1

```powershell
Remove-JiraIssueLink 1234,2345
```

Removes two issue links with id 1234 and 2345

### EXAMPLE 2

```powershell
Get-JiraIssue -Query "project = Project1 AND label = lingering" | Remove-JiraIssueLink
```

Removes all issue links for all issues in project Project1 and that have a label "lingering"

## PARAMETERS

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
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IssueLink

IssueLink to delete

```yaml
Type: IssueLink[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByIssueLink
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Issue

Issue whose links should all be removed.

```yaml
Type: Issue[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByIssue
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
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

### AtlassianPS.JiraPS.Issue

### AtlassianPS.JiraPS.IssueLink


## OUTPUTS

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Add-JiraIssueLink](../Add-JiraIssueLink/)

[Get-JiraIssue](../Get-JiraIssue/)

[Get-JiraIssueLink](../Get-JiraIssueLink/)
