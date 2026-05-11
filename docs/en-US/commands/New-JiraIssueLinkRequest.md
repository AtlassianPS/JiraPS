---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/New-JiraIssueLinkRequest/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/New-JiraIssueLinkRequest/
---
# New-JiraIssueLinkRequest

## SYNOPSIS

Creates a typed issue-link create request payload.

## SYNTAX

```powershell
New-JiraIssueLinkRequest [-LinkType] <IssueLinkType> [-FromIssue] <Issue> [-ToIssue] <Issue> [<CommonParameters>]
```

## DESCRIPTION

Builds an `AtlassianPS.JiraPS.IssueLinkCreateRequest` object that can be passed to `Add-JiraIssueLink`.
Use this helper when you want a simple `-Type`, `-FromIssue`, and `-ToIssue` authoring experience instead of manually composing nested request objects.

## EXAMPLES

### EXAMPLE 1

```powershell
$_issueLink = New-JiraIssueLinkRequest -Type "Blocks" -FromIssue "TEST-01" -ToIssue "TEST-10"
Add-JiraIssueLink -IssueLink $_issueLink
```

Creates an issue-link request from simple string inputs and posts the link to Jira.

## PARAMETERS

### -FromIssue

The source issue to map to Jira's `inwardIssue` request slot.

```yaml
Type: Issue
DefaultValue: ''
SupportsWildcards: false
Aliases:
- InwardIssue
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -LinkType

The issue-link type reference.
Simple string input maps to the link-type name.
For id-based requests, pass an `AtlassianPS.JiraPS.IssueLinkType` object with `Id` populated.

```yaml
Type: IssueLinkType
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Type
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

### -ToIssue

The destination issue to map to Jira's `outwardIssue` request slot.

```yaml
Type: Issue
DefaultValue: ''
SupportsWildcards: false
Aliases:
- OutwardIssue
ParameterSets:
- Name: (All)
  Position: 2
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
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable.
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.IssueLinkType

The issue-link type reference that identifies the Jira link relationship.

### AtlassianPS.JiraPS.Issue

The issues that should be used as source and destination link references.

## OUTPUTS

### AtlassianPS.JiraPS.IssueLinkCreateRequest

A typed request payload suitable for `Add-JiraIssueLink`.

## RELATED LINKS

[Add-JiraIssueLink](../Add-JiraIssueLink/)
