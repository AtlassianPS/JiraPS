---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Get-JiraRemoteLink

## SYNOPSIS
Returns a remote link from a Jira issue

## SYNTAX

```
Get-JiraRemoteLink [-Issue] <String[]> [-LinkId <Int32>] [-Credential <PSCredential>]
```

## DESCRIPTION
This function returns information on remote links from a  JIRA issue.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-JiraRemoteLink -Issue Project1-1000 -Credential $cred
```

Returns information about all remote links from the issue "Project1-1000"

### -------------------------- EXAMPLE 2 --------------------------
```
Get-JiraRemoteLink -Issue Project1-1000 -LinkId 100000 -Credential $cred
```

Returns information about a specific remote link from the issue "Project1-1000"

## PARAMETERS

### -Issue
The Issue Object or ID to link.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Key

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -LinkId
Get a single link by it's id.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
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
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### [Object[]] The issue to look up in JIRA. This can be a String or a JiraPS.Issue object.

## OUTPUTS

### [JiraPS.Link]

## NOTES

## RELATED LINKS

