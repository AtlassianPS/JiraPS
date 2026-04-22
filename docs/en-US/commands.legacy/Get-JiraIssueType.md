---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueType/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueType/
---
# Get-JiraIssueType

## SYNOPSIS

Returns information about the available issue type in JIRA.

## SYNTAX

### _All (Default)

```powershell
Get-JiraIssueType [-Force] [-Credential <PSCredential>] [<CommonParameters>]
```

### _Search

```powershell
Get-JiraIssueType [-IssueType] <String[]> [-Force] [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

This function retrieves all the available IssueType on the JIRA server an returns them as `JiraPS.IssueType`.

This function can restrict the output to a subset of the available IssueTypes if told so.

Results are cached for 60 minutes to improve performance. Use `-Force` to bypass the cache and fetch fresh data.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraIssueType
```

This example returns all the IssueTypes on the JIRA server.

### EXAMPLE 2

```powershell
Get-JiraIssueType -IssueType "Bug"
```

This example returns only the IssueType "Bug".

### EXAMPLE 3

```powershell
Get-JiraIssueType -IssueType "Bug","Task","4"
```

This example return the information about the IssueType named "Bug" and "Task" and with id "4".

## PARAMETERS

### -IssueType

The Issue Type name or ID to search.

```yaml
Type: String[]
Parameter Sets: _Search
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Force

Bypass the cache and fetch fresh data from the server.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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

### [JiraPS.IssueType]

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraIssue](../Get-JiraIssue/)
