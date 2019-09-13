---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraPriority/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraPriority/
---
# Get-JiraPriority

## SYNOPSIS

Returns information about the available priorities in JIRA.

## SYNTAX

### _All (Default)

```powershell
Get-JiraPriority [-Session <PSObject>] [<CommonParameters>]
```

### _Search

```powershell
Get-JiraPriority [-Id] <Int32[]> [-Session <PSObject>] [<CommonParameters>]
```

## DESCRIPTION

This function retrieves all the available Priorities on the JIRA server an returns them as `JiraPS.Priority`.

This function can restrict the output to a subset of the available IssueTypes if told so.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraPriority
```

This example returns all the IssueTypes on the JIRA server.

### EXAMPLE 2

```powershell
Get-JiraPriority -ID 1
```

This example returns only the Priority with ID 1.

## PARAMETERS

### -Id

ID of the priority to get.

```yaml
Type: Int32[]
Parameter Sets: _Search
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Session

Session to use to connect to JIRA.  
If not specified, this function will use default session.
The name of a session, PSCredential object or session's instance itself is accepted to pass as value for the parameter.

```yaml
Type: psobject
Parameter Sets: (All)
Aliases: Credential

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

## OUTPUTS

### [JiraPS.Priority]

## NOTES

This function requires either the `-Session` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

Remaining operations for `priority` have not yet been implemented in the module.

## RELATED LINKS
