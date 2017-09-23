---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Get-JiraPriority

## SYNOPSIS
Returns information about the available priorities in JIRA.

## SYNTAX

```
Get-JiraPriority [[-Id] <Int32>] [[-Credential] <PSCredential>]
```

## DESCRIPTION
This function retrieves all the available Priorities on the JIRA server an returns them as JiraPS.Priority.

This function can restrict the output to a subset of the available IssueTypes if told so.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-JiraPriority
```

This example returns all the IssueTypes on the JIRA server.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-JiraPriority -ID 1
```

This example returns only the Priority with ID 1.

## PARAMETERS

### -Id
ID of the priority to get.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
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
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### This function outputs the JiraPS.Priority object retrieved.

## NOTES
This function requires either the -Credential parameter to be passed or a persistent JIRA session.
See New-JiraSession for more details. 
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

