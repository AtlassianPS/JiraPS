---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Get-JiraField

## SYNOPSIS
This function returns information about JIRA fields

## SYNTAX

```
Get-JiraField [[-Field] <String[]>] [-Credential <PSCredential>]
```

## DESCRIPTION
This function provides information about JIRA fields, or about one field in particular. 
This is a good way to identify a field's ID by its name, or vice versa.

Typically, this information is only needed when identifying what fields are necessary to create or edit issues.
See Get-JiraIssueCreateMetadata for more details.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-JiraField
```

This example returns information about all JIRA fields visible to the current user (or using anonymous access if a JiraPS session has not been defined).

### -------------------------- EXAMPLE 2 --------------------------
```
Get-JiraField IssueKey
```

This example returns information about the IssueKey field.

## PARAMETERS

### -Field
The Field name or ID to search.

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

### This function does not accept pipeline input.

## OUTPUTS

### This function outputs the JiraPS.Field object(s) that represent the JIRA field(s).

## NOTES
This function requires either the -Credential parameter to be passed or a persistent JIRA session.
See New-JiraSession for more details. 
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

