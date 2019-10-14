---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraBoard/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraBoard/
---
# Get-JiraBoard

## SYNOPSIS

Returns boards from Jira

## SYNTAX

### _All (Default)

```powershell
Get-JiraBoard [[-StartIndex] <UInt32>] [[-MaxResults] <UInt32>] [[PageSize] <UInt32>]
 [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>] [-Credential <PSCredential>] [<CommonParameters>]
```

### _Search

```powershell
Get-JiraBoard [-Board] <String[]> [[-StartIndex] <UInt32>] [[-MaxResults] <UInt32>] [[PageSize] <UInt32>]
 [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>] [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

This function returns information regarding Boards from Jira.

If the Board parameter is not supplied,
it will return information about all boards the given user is authorized to view.

The `-Board` parameter will accept a full or part board name.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraBoard -Board TEST -Credential $cred
```

Returns information about any boards that fully or partially match the board name TEST

### EXAMPLE 2

```powershell
Get-JiraBoard
```

Returns information about all boards the user is authorized to view

## PARAMETERS

### -Board

The string within the Board name to search.

```yaml
Type: String[]
Parameter Sets: _Search
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
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
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (<http://go.microsoft.com/fwlink/?LinkID=113216>).

## INPUTS

## OUTPUTS

### [JiraPS.Board]

## NOTES

By default, this will return all boards.
For large numbers of boards, this can take quite some time.

To limit the number of boards returned, use the MaxResults parameter.
You can also combine this with the `-StartIndex` parameter to "page" through results.

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

Remaining operations for `board` have not yet been implemented in the module.

## RELATED LINKS
