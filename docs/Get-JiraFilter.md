---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Get-JiraFilter

## SYNOPSIS
Returns information about a filter in JIRA

## SYNTAX

### ByFilterID (Default)
```
Get-JiraFilter [-Id] <String[]> [-Credential <PSCredential>]
```

### ByInputObject
```
Get-JiraFilter -InputObject <Object[]> [-Credential <PSCredential>]
```

## DESCRIPTION
This function returns information about a filter in JIRA, including the JQL syntax of the filter, its owner, and sharing status.

This function is only capable of returning filters by their Filter ID.
This is a limitation of JIRA's REST API. 
The easiest way to obtain the ID of a filter is to load the filter in the "regular" Web view of JIRA, then copy the ID from the URL of the page.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-JiraFilter -Id 12345
```

Gets a reference to filter ID 12345 from JIRA

### -------------------------- EXAMPLE 2 --------------------------
```
$filterObject | Get-JiraFilter
```

Gets the information of a filter by providing a filter object

## PARAMETERS

### -Id
ID of the filter to search for.

```yaml
Type: String[]
Parameter Sets: ByFilterID
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject
Object of the filter to search for.

```yaml
Type: Object[]
Parameter Sets: ByInputObject
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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

### [Object[]] The filter to look up in JIRA. This can be a String (filter ID) or a JiraPS.Filter object.

## OUTPUTS

### [JiraPS.Filter[]] Filter objects

## NOTES

## RELATED LINKS

