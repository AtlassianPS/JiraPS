---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraGroupMember/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraGroupMember/
---
# Get-JiraGroupMember

## SYNOPSIS

Returns members of a given group in JIRA

## SYNTAX

```powershell
Get-JiraGroupMember [-Group] <Object[]> [[-IncludeInactive] <Switch>] [[-StartIndex] <UInt32>] [[-MaxResults] <UInt32>]
 [[PageSize] <UInt32>] [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>] [[-Credential] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

This function returns members of a provided group in JIRA.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraGroupMember testGroup
```

This example returns all members of the JIRA group testGroup.

### EXAMPLE 2

```powershell
Get-JiraGroup 'Developers' | Get-JiraGroupMember
```

This example illustrates the use of the pipeline to return members of
the Developers group in JIRA.

## PARAMETERS

### -Group

Group object of which to display the members.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -IncludeInactive

Include inactive users in the results.

By default they are not shown.

```yaml
Type: Switch
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize

Maximum number of results to fetch per call.

This setting can be tuned to get better performance according to the load on the server.

> Warning: too high of a PageSize can cause a timeout on the request.

```yaml
Type: UInt32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 25
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartIndex

> NOTE: This parameter has been marked as deprecated and will be removed with the next major release.
> Use `-Skip` instead.

Index of the first user to return.

This can be used to "page" through users in a large group or a slow connection.

```yaml
Type: UInt32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxResults

> NOTE: This parameter has been marked as deprecated and will be removed with the next major release.
> Use `-First` instead.

Maximum number of results to return.

By default, all users will be returned.

```yaml
Type: UInt32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 0
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

### -Credential

Credentials to use to connect to JIRA.  
If not specified, this function will use anonymous access.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [JiraPS.Group]

The group to query for members

## OUTPUTS

### [JiraPS.User]

## NOTES

By default, this will return all active users who are members of the given group.
For large groups, this can take quite some time.

To limit the number of group members returned, use the MaxResults parameter.
You can also combine this with the `-StartIndex` parameter to "page" through results.

This function does not return inactive users.
This appears to be a limitation of JIRA's REST API.

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraGroup](../Get-JiraGroup/)

[Add-JiraGroupMember](../Add-JiraGroupMember/)

[New-JiraGroup](../New-JiraGroup/)

[New-JiraUser](../New-JiraUser/)

[Remove-JiraGroupMember](../Remove-JiraGroupMember/)
