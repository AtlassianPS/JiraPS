---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueLinkType/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueLinkType/
---
# Get-JiraIssueLinkType

## SYNOPSIS

Gets available issue link types

## SYNTAX

### _All (Default)

```powershell
Get-JiraIssueLinkType [-Credential <PSCredential>] [<CommonParameters>]
```

### _Search

```powershell
Get-JiraIssueLinkType [-LinkType] <Object> [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

This function gets available issueLink types from a JIRA server.
It can also return specific information about a single issueLink type.

This is a useful function for discovering data about issueLink types in order to create and modify issueLinks on issues.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraIssueLinkType
```

This example returns all available links from the JIRA server

### EXAMPLE 2

```powershell
Get-JiraIssueLinkType -LinkType 1
```

This example returns information about the link type with ID 1.

## PARAMETERS

### -LinkType

The Issue Type name or ID to search.

```yaml
Type: Object
Parameter Sets: _Search
Aliases:

Required: True
Position: 1
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
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [Int[]]

## OUTPUTS

### [JiraPS.IssueLinkType]

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

Remaining operations for `issuetype` have not yet been implemented in the module.

## RELATED LINKS

[Add-JiraIssueLink](../Add-JiraIssueLink/)

[Get-JiraIssueLink](../Get-JiraIssueLink/)

[Remove-JiraIssueLink](../Remove-JiraIssueLink/)
