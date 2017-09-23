---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Get-JiraSession

## SYNOPSIS
Obtains a reference to the currently saved JIRA session

## SYNTAX

```
Get-JiraSession
```

## DESCRIPTION
This functio obtains a reference to the currently saved JIRA session. 
This can provide
a JIRA session ID, as well as the username used to connect to JIRA.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
New-JiraSession -Credential (Get-Credential jiraUsername)
```

Get-JiraSession
Creates a Jira session for jiraUsername, then obtains a reference to it.

## PARAMETERS

## INPUTS

### None

## OUTPUTS

### [JiraPS.Session] An object representing the Jira session

## NOTES

## RELATED LINKS

