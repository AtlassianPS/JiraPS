---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# New-JiraSession

## SYNOPSIS
Creates a persistent JIRA authenticated session which can be used by other JiraPS functions

## SYNTAX

```
New-JiraSession [-Credential] <PSCredential>
```

## DESCRIPTION
This function creates a persistent, authenticated session in to JIRA which can be used by all other
JiraPS functions instead of explicitly passing parameters. 
This removes the need to use the
-Credential parameter constantly for each function call.

This is the equivalent of a browser cookie saving login information.

Session data is stored in this module's PrivateData; it is not necessary to supply it to each
subsequent function.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
New-JiraSession -Credential (Get-Credential jiraUsername)
```

Get-JiraIssue TEST-01
Creates a Jira session for jiraUsername. 
The following Get-JiraIssue is run using the
saved session for jiraUsername.

## PARAMETERS

### -Credential
Credentials to use to connect to JIRA.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### [PSCredential] The credentials to use to create the Jira session

## OUTPUTS

### [JiraPS.Session] An object representing the Jira session

## NOTES

## RELATED LINKS

