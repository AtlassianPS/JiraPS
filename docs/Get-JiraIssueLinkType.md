---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Get-JiraIssueLinkType

## SYNOPSIS
Gets available issue link types

## SYNTAX

```
Get-JiraIssueLinkType [[-LinkType] <Object>] [-Credential <PSCredential>]
```

## DESCRIPTION
This function gets available issue link types from a JIRA server.
It can also return specific information about a single issue link type.

This is a useful function for discovering data about issue link types in order to create and modify issue links on issues.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-JiraIssueLinkType
```

This example returns all available links fron the JIRA server

### -------------------------- EXAMPLE 2 --------------------------
```
Get-JiraIssueLinkType -LinkType 1
```

This example returns information about the link type with ID 1.

## PARAMETERS

### -LinkType
The Issue Type name or ID to search

```yaml
Type: Object
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: None
Accept pipeline input: False
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

### This function does not accept pipeline input.

## OUTPUTS

### This function outputs the JiraPS.IssueLinkType object(s) that represent the JIRA issue link type(s).

## NOTES
This function requires either the -Credential parameter to be passed or a persistent JIRA session.
See New-JiraSession for more details. 
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

