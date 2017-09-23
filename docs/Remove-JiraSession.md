---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Remove-JiraSession

## SYNOPSIS
Removes a persistent JIRA authenticated session

## SYNTAX

```
Remove-JiraSession [[-Session] <Object>]
```

## DESCRIPTION
This function removes a persistent JIRA authenticated session and closes the session for JIRA.
This can be used to "log out" of JIRA once work is complete.

If called with the Session parameter, this function will attempt to close the provided
JiraPS.Session object.

If called with no parameters, this function will close the saved JIRA session in the module's
PrivateData.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
New-JiraSession -Credential (Get-Credential jiraUsername)
```

Get-JiraIssue TEST-01
Remove-JiraSession
This example creates a JIRA session for jiraUsername, runs Get-JiraIssue, and closes the JIRA session.

### -------------------------- EXAMPLE 2 --------------------------
```
$s = New-JiraSession -Credential (Get-Credential jiraUsername)
```

Remove-JiraSession $s
This example creates a JIRA session and saves it to a variable, then uses the variable reference to
close the session.

## PARAMETERS

### -Session
A Jira session to be closed.
If not specified, this function will use a saved session.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

## INPUTS

### [JiraPS.Session] A Session object to close.

## OUTPUTS

### [JiraPS.Session] An object representing the Jira session

## NOTES

## RELATED LINKS

