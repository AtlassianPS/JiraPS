---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueLinkType/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueLinkType/
---
# Get-JiraIssueLinkType

## SYNOPSIS

Gets available issue link types.

## SYNTAX

### _All (Default)

```powershell
Get-JiraIssueLinkType [-Credential <pscredential>] [<CommonParameters>]
```

### _Search

```powershell
Get-JiraIssueLinkType [-LinkType] <AtlassianPS.JiraPS.IssueLinkType> [-Credential <pscredential>]
 [<CommonParameters>]
```

## DESCRIPTION

This function gets available issueLink types from a Jira server.
It can also return specific information about a single issueLink type.

This is a useful function for discovering data about issueLink types in order to create and modify issueLinks on issues.

## EXAMPLES

### Example 1

```powershell
Get-JiraIssueLinkType
```

This example returns all available links from the Jira server

### Example 2

```powershell
Get-JiraIssueLinkType -LinkType 1
```

This example returns information about the link type with ID 1.

## PARAMETERS

### -Credential

Credentials to use to connect to Jira.
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

### -LinkType

The issue link type name or ID to search.

```yaml
Type: AtlassianPS.JiraPS.IssueLinkType
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: _Search
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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable.
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### AtlassianPS.JiraPS.IssueLinkType

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent Jira session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to Jira.

Remaining operations for `issuetype` have not yet been implemented in the module.

## RELATED LINKS

[Add-JiraIssueLink](../Add-JiraIssueLink/)

[Get-JiraIssueLink](../Get-JiraIssueLink/)

[Remove-JiraIssueLink](../Remove-JiraIssueLink/)
