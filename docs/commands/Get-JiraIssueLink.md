---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueLink/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueLink/
---
# Get-JiraIssueLink

## SYNOPSIS

Returns a specific issueLink from Jira

## SYNTAX

```powershell
Get-JiraIssueLink [-Id] <Int32[]> [[-Credential] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

This function returns information regarding a specified issueLink from Jira.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraIssueLink 10000
```

Description  
 -----------  
Returns information about the IssueLink with ID 10000

### EXAMPLE 2

```powershell
Get-JiraIssueLink -IssueLink 10000
```

Description  
 -----------  
Returns information about the IssueLink with ID 10000

### EXAMPLE 3

```powershell
(Get-JiraIssue TEST-01).issuelinks | Get-JiraIssueLink
```

Description  
 -----------  
Returns the information about all IssueLinks in issue TEST-01

## PARAMETERS

### -Id

The IssueLink ID to search.

Accepts input from pipeline when the object is of type `JiraPS.IssueLink`

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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
Position: 2
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

### [JiraPS.IssueLink]

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Add-JiraIssueLink](../Add-JiraIssueLink/)

[Get-JiraIssueLinkType](../Get-JiraIssueLinkType/)

[Remove-JiraIssueLink](../Remove-JiraIssueLink/)
