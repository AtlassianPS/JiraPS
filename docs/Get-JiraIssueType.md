---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Get-JiraIssueType

## SYNOPSIS
Returns information about the available issue type in JIRA.

## SYNTAX

```
Get-JiraIssueType [[-IssueType] <String[]>] [-Credential <PSCredential>]
```

## DESCRIPTION
This function retrieves all the available IssueType on the JIRA server an returns them as JiraPS.IssueType.

This function can restrict the output to a subset of the available IssueTypes if told so.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-JiraIssueType
```

This example returns all the IssueTypes on the JIRA server.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-JiraIssueType -IssueType "Bug"
```

This example returns only the IssueType "Bug".

### -------------------------- EXAMPLE 3 --------------------------
```
Get-JiraIssueType -IssueType "Bug","Task","4"
```

This example return the information about the IssueType named "Bug" and "Task" and with id "4".

## PARAMETERS

### -IssueType
The Issue Type name or ID to search.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: 

Required: False
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

## INPUTS

### This function accepts Strings via the pipeline.

## OUTPUTS

### This function outputs the JiraPS.IssueType object retrieved.

## NOTES
This function requires either the -Credential parameter to be passed or a persistent JIRA session.
See New-JiraSession for more details. 
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

