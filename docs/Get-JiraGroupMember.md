---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Get-JiraGroupMember

## SYNOPSIS
Returns members of a given group in JIRA

## SYNTAX

```
Get-JiraGroupMember [-Group] <Object> [-StartIndex <Int32>] [-MaxResults <Int32>] [-Credential <PSCredential>]
```

## DESCRIPTION
This function returns members of a provided group in JIRA.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-JiraGroupmember testGroup
```

This example returns all members of the JIRA group testGroup.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-JiraGroup 'Developers' | Get-JiraGroupMember
```

This example illustrates the use of the pipeline to return members of
the Developers group in JIRA.

## PARAMETERS

### -Group
Group object of which to display the members.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -StartIndex
Index of the first user to return.
This can be used to "page" through
users in a large group or a slow connection.

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

### -MaxResults
Maximum number of results to return.
By default, all users will be
returned.

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

### [JiraPS.Group] The group to query for members

## OUTPUTS

### [JiraPS.User[]] Members of the provided group

## NOTES
By default, this will return all active users who are members of the
given group. 
For large groups, this can take quite some time.

To limit the number of group members returned, use
the MaxResults parameter. 
You can also combine this with the
StartIndex parameter to "page" through results.

This function does not return inactive users. 
This appears to be a
limitation of JIRA's REST API.

## RELATED LINKS

