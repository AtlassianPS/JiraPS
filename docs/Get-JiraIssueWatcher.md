---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Get-JiraIssueWatcher

## SYNOPSIS
Returns watchers on an issue in JIRA.

## SYNTAX

```
Get-JiraIssueWatcher [-Issue] <Object> [-Credential <PSCredential>]
```

## DESCRIPTION
This function obtains watchers from existing issues in JIRA.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-JiraIssueWatcher -Key TEST-001
```

This example returns all watchers posted to issue TEST-001.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-JiraIssue TEST-002 | Get-JiraIssueWatcher
```

This example illustrates use of the pipeline to return all watchers on issue TEST-002.

## PARAMETERS

### -Issue
JIRA issue to check for watchers.
Can be a JiraPS.Issue object, issue key, or internal issue ID.

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

### This function can accept JiraPS.Issue objects, Strings, or Objects via the pipeline.  It uses Get-JiraIssue to identify the issue parameter; see its Inputs section for details on how this function handles inputs.

## OUTPUTS

### This function outputs all JiraPS.Watchers issues associated with the provided issue.

## NOTES
This function requires either the -Credential parameter to be passed or a persistent JIRA session.
See New-JiraSession for more details. 
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

