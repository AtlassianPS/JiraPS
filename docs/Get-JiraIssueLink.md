---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Get-JiraIssueLink

## SYNOPSIS
Returns a specific issueLink from Jira

## SYNTAX

```
Get-JiraIssueLink [-Id] <Int32[]> [-Credential <PSCredential>]
```

## DESCRIPTION
This function returns information regarding a specified issueLink from Jira.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-JiraIssueLink 10000
```

Returns information about the IssueLink with ID 10000

### -------------------------- EXAMPLE 2 --------------------------
```
Get-JiraIssueLink -IssueLink 10000
```

Returns information about the IssueLink with ID 10000

### -------------------------- EXAMPLE 3 --------------------------
```
(Get-JiraIssue TEST-01).issuelinks | Get-JiraIssueLink
```

Returns the information about all IssueLinks in issue TEST-01

## PARAMETERS

### -Id
The IssueLink ID to search

Accepts input from pipeline when the object is of type JiraPS.IssueLink

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
Credentials to use to connect to Jira

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

### [Int[]] issueLink ID
[PSCredential] Credentials to use to connect to Jira

## OUTPUTS

### [JiraPS.IssueLink]

## NOTES

## RELATED LINKS

