---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraRemoteLink/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraRemoteLink/
---
# Get-JiraRemoteLink

## SYNOPSIS

Returns a remote link from a Jira issue

## SYNTAX

```powershell
Get-JiraRemoteLink [-Issue] <Object> [[-LinkId] <Int32>] [[-Credential] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

This function returns information on remote links from a  JIRA issue.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraRemoteLink -Issue TEST-001 -Credential $cred
```

Description  
 -----------  
Returns information about all remote links from the issue "TEST-001"

### EXAMPLE 2

```powershell
Get-JiraRemoteLink -Issue TEST-001 -LinkId 100000 -Credential $cred
```

Description  
 -----------  
Returns information about a specific remote link from the issue "TEST-001"

## PARAMETERS

### -Issue

The Issue to search for link.

Can be a `JiraPS.Issue` object, issue key, or internal issue ID.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: Key

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -LinkId

Get a single link by it's id.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 0
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
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [JiraPS.Issue] / [String]

## OUTPUTS

### [JiraPS.Link]

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Remove-JiraRemoteLink](../Remove-JiraRemoteLink/)
