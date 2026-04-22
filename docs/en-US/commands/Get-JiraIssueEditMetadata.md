---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueEditMetadata/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueEditMetadata/
---
# Get-JiraIssueEditMetadata

## SYNOPSIS

Returns metadata required to change an issue in JIRA

## SYNTAX

```powershell
Get-JiraIssueEditMetadata [-Issue] <string> [[-Credential] <pscredential>] [<CommonParameters>]
```

## DESCRIPTION

This function returns metadata required to update an issue in JIRA - the fields that can be defined in the process of updating an issue.
This can be used to identify custom fields in order to pass them to `Set-JiraIssue`.

This function is particularly useful when your JIRA instance includes custom fields that are marked as mandatory.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraIssueEditMetadata -Issue "TEST-001"
```

This example returns the fields available when updating the issue "TEST-001".

### EXAMPLE 2

```powershell
Get-JiraIssueEditMetadata -Issue "TEST-001" | ? {$_.Required -eq $true}
```

This example returns fields available when updating the issue "TEST-001".
It then uses `Where-Object` (aliased by the question mark) to filter only the fields that are required.

## PARAMETERS

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

### -Issue

Issue id or key of the reference issue.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
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

## OUTPUTS

### JiraPS.Field

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[about_JiraPS_UpdatingIssues](../../about/updating-issues.html)

[Get-JiraField](../Get-JiraField/)

[Set-JiraIssue](../Set-JiraIssue/)
