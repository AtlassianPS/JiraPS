---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Add-JiraIssueLink/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Add-JiraIssueLink/
---
# Add-JiraIssueLink

## SYNOPSIS

Adds a link between two Issues on Jira

## SYNTAX

```powershell
Add-JiraIssueLink [-IssueLink] <IssueLinkCreateRequest[]> [[-Comment] <string>] [[-Credential] <pscredential>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Creates a new link of the specified type between two issues.

## EXAMPLES

### EXAMPLE 1

```powershell
$_issueLink = [AtlassianPS.JiraPS.IssueLinkCreateRequest]@{
    inwardIssue = [AtlassianPS.JiraPS.LinkedIssueRef]@{ key = "TEST-01" }
    outwardIssue = [AtlassianPS.JiraPS.LinkedIssueRef]@{ key = "TEST-10" }
    type = [AtlassianPS.JiraPS.IssueLinkTypeRef]@{ name = "Composition" }
}
Add-JiraIssueLink -IssueLink $_issueLink
```

Creates a link "is part of" between TEST-01 and TEST-10

### EXAMPLE 2

```powershell
$_issueLink = New-JiraIssueLinkRequest -Type "Blocks" -FromIssue "TEST-01" -ToIssue "TEST-10"
Add-JiraIssueLink -IssueLink $_issueLink
```

Creates a link using the helper cmdlet's simple `-Type` / `-FromIssue` / `-ToIssue` signature.

## PARAMETERS

### -Comment

Write a comment to the issue

```yaml
Type: String
DefaultValue: ''
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
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IssueLink

Issue Link to be created.
Accepts `AtlassianPS.JiraPS.IssueLinkCreateRequest` values and compatible payload objects that include `type`, `inwardIssue`, and `outwardIssue`.
The nested `type` object must include `name` or `id`.
The nested issue references must include `key` or `id`.
Both `inwardIssue` and `outwardIssue` are required.

```yaml
Type: IssueLinkCreateRequest[]
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

### AtlassianPS.JiraPS.IssueLinkCreateRequest

The issue-link create request payload that should be used.

## OUTPUTS

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraIssue](../Get-JiraIssue/)

[Get-JiraIssueLink](../Get-JiraIssueLink/)

[Get-JiraIssueLinkType](../Get-JiraIssueLinkType/)

[New-JiraIssueLinkRequest](../New-JiraIssueLinkRequest/)

[Remove-JiraIssueLink](../Remove-JiraIssueLink/)
