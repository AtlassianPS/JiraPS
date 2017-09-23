---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Get-JiraIssue

## SYNOPSIS
Returns information about an issue in JIRA.

## SYNTAX

### ByIssueKey (Default)
```
Get-JiraIssue [-Key] <String[]> [-Credential <PSCredential>]
```

### ByInputObject
```
Get-JiraIssue [-InputObject] <Object[]> [-Credential <PSCredential>]
```

### ByJQL
```
Get-JiraIssue -Query <String> [-StartIndex <Int32>] [-MaxResults <Int32>] [-PageSize <Int32>]
 [-Credential <PSCredential>]
```

### ByFilter
```
Get-JiraIssue [-Filter <Object>] [-StartIndex <Int32>] [-MaxResults <Int32>] [-PageSize <Int32>]
 [-Credential <PSCredential>]
```

## DESCRIPTION
This function obtains references to issues in JIRA.

This function can be used to directly query JIRA for a specific issue key or internal issue ID.
It can also be used to query JIRA for issues matching a specific criteria using JQL (Jira Query Language).

For more details on JQL syntax, see this articla from Atlassian: https://confluence.atlassian.com/display/JIRA/Advanced+Searching

Output from this function can be piped to various other functions in this module, including Set-JiraIssue, Add-JiraIssueComment, and Invoke-JiraIssueTransition.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-JiraIssue -Key TEST-001
```

This example returns a reference to JIRA issue TEST-001.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-JiraIssue "TEST-002" | Add-JiraIssueComment "Test comment from PowerShell"
```

This example illustrates pipeline use from Get-JiraIssue to Add-JiraIssueComment.

### -------------------------- EXAMPLE 3 --------------------------
```
= -5d'
```

This example illustrates using the Query parameter and JQL syntax to query Jira for matching issues.

### -------------------------- EXAMPLE 4 --------------------------
```
Get-JiraIssue -InputObject $oldIssue
```

This example illustrates how to get an update of an issue from an old result of Get-JiraIssue stored in $oldIssue.

### -------------------------- EXAMPLE 5 --------------------------
```
Get-JiraFilter -Id 12345 | Get-JiraIssue
```

This example retrieves all issues that match the criteria in the saved fiilter with id 12345.

## PARAMETERS

### -Key
Key of the issue to search for.

```yaml
Type: String[]
Parameter Sets: ByIssueKey
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject
Object of an issue to search for.

```yaml
Type: Object[]
Parameter Sets: ByInputObject
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Query
JQL query for which to search for.

```yaml
Type: String
Parameter Sets: ByJQL
Aliases: JQL

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
Object of an existing JIRA filter from which the results will be returned.

```yaml
Type: Object
Parameter Sets: ByFilter
Aliases: 

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartIndex
Index of the first issue to return.
This can be used to "page" through
issues in a large collection or a slow connection.

```yaml
Type: Int32
Parameter Sets: ByJQL, ByFilter
Aliases: 

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxResults
Maximum number of results to return.
By default, all issues will be
returned.

```yaml
Type: Int32
Parameter Sets: ByJQL, ByFilter
Aliases: 

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
How many issues should be returned per call to JIRA.
This parameter
only has effect if $MaxResults is not provided or set to 0.
Normally,
you should not need to adjust this parameter, but if the REST calls
take a long time, try playing with different values here.

```yaml
Type: Int32
Parameter Sets: ByJQL, ByFilter
Aliases: 

Required: False
Position: Named
Default value: 50
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

### This function can accept JiraPS.Issue objects, Strings, or Objects via the pipeline.

* If a JiraPS.Issue object is passed, this function returns a new reference to the same issue.
 * If a String is passed, this function searches for an issue with that issue key or internal ID.
 * If an Object is passed, this function invokes its ToString() method and treats it as a String.

## OUTPUTS

### This function outputs the JiraPS.Issue object retrieved.

## NOTES
This function requires either the -Credential parameter to be passed or a persistent JIRA session.
See New-JiraSession for more details. 
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

