---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Find-JiraFilter/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Find-JiraFilter/
---
# Find-JiraFilter

## SYNOPSIS

Find JIRA filter(s).

## SYNTAX

### ByAccountId

```powershell
Find-JiraFilter [[-Name] <string[]>] [[-AccountId] <string>] [[-GroupName] <string>] [[-Project] <Object>] [[-Fields] {description | favourite | favouritedCount | jql | owner |
    searchUrl | sharePermissions | subscriptions | viewUrl}] [[-Sort] <string>] [[-Session] <PSObject>] [-IncludeTotalCount] [-Skip <uint64>] [-First <uint64>]
    [<CommonParameters>]
```

### ByOwner

```powershell
Find-JiraFilter [[-Name] <string[]>] [-Owner] <string> [[-GroupName] <string>] [[-Project] <Object>] [[-Fields] {description | favourite | favouritedCount | jql | owner |
    searchUrl | sharePermissions | subscriptions | viewUrl}] [[-Sort] <string>] [[-Session] <PSObject>] [-IncludeTotalCount] [-Skip <uint64>] [-First <uint64>]
    [<CommonParameters>]
```

## DESCRIPTION

Searches for filters. This operation is similar to Get filters except that the results can be refined to include filters that have specific attributes. For example, filters with a particular name. When multiple attributes are specified only filters matching all attributes are returned.

Disclaimer

> This works with Jira Cloud only.  It does not work with non-cloud Jira Server (v8.3.1 at the time of this writing).

## EXAMPLES

### EXAMPLE 1

```powershell
Find-JiraFilter -Name 'ABC'
```

This example finds all JIRA filters that include ABC in the name.  The search is case insensitive.

### EXAMPLE 2

```powershell
Find-JiraFilter -Name """George Jetsons Filter"""
```

This example finds a JIRA filter by exact name (case insensitive)

### EXAMPLE 3

```powershell
'My','Your' | Find-JiraFilter
```

This example demonstrates use of the pipeline to search for multiple filter Name(s).  The search is case insensitive.

### EXAMPLE 4

```powershell
Find-JiraFilter -Name 'My','Your'
```

This example demonstrates the use of a list of names to search for multiple filter Name(s).  The search is case insensitive.

### EXAMPLE 5

```powershell
Find-JiraFilter -AccountId 'c62dde3418235be1c8424950' -First 3 -Skip 3
```

This example finds all JIRA filters belonging to a specific owner, and illustrates the use of the -First and -Skip Paging parameters.

### EXAMPLE 6

```powershell
Find-JiraFilter -Project 'TEST' -First 8
```

This example finds all JIRA filters belonging to project TEST.

### Example 7

```powershell
Find-JiraFilter -Name """George Jetsons Filter""" -Fields 'description','jql'
```

This example finds the JIRA filter named "George Jetsons Filter" but only expands the fields listed.

By retrieving only the data really needed, the payload the server sends is
reduced, which speeds up the search.

## PARAMETERS

### -Name

String used to perform a case-insensitive partial match with name.  An exact match can be requested by including quotes (refer to the examples above).

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -AccountId

User AccountId used to return filters with the matching owner.accountId.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Owner

User Object or user name used to return filters with the matching owner.accountId.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: UserName

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -GroupName

Group name used to return filters that are shared with a group that matches sharePermissions.group.groupname.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Project

The ID or Key of the Project to search.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Fields

Field you would like to select from your issue. By default, all fields are
returned.

Allows any combination of the following values:

- description
- favourite
- favouritedCount
- jql
- owner
- searchUrl
- sharePermissions
- subscriptions
- viewUrl

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 'description','favourite','favouritedCount','jql','owner','searchUrl','sharePermissions','subscriptions','viewUrl'
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sort

Orders the results using one of these filter properties:

- *description* Orders by filter description. Note that this ordering works independently of whether the expand to display the description field is in use.
- *favourite_count* Orders by favouritedCount.
- *is_favourite* Orders by favourite.
- *id* Orders by filter id.
- *name* Orders by filter name.
- *owner* Orders by owner.accountId.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeTotalCount

Causes an extra output of the total count at the beginning.

Note this is actually a uInt64, but with a custom string representation.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Skip

Controls how many things will be skipped before starting output.

Defaults to 0.

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -First

Indicates how many items to return.

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 18446744073709551615
Accept pipeline input: False
Accept wildcard characters: False
```

### -Session

Session to use to connect to JIRA.  
If not specified, this function will use default session.
The name of a session, PSCredential object or session's instance itself is accepted to pass as value for the parameter.

```yaml
Type: psobject
Parameter Sets: (All)
Aliases: Credential

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216)

## INPUTS

## OUTPUTS

### [JiraPS.Filter[]]

## NOTES

This function requires either the `-Session` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraFilter](../Get-JiraFilter/)

[Get-JiraProject](../Get-JiraProject/)

[Get-JiraUser](../Get-JiraUser/)
