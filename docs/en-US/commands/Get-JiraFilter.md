---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraFilter/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraFilter/
---
# Get-JiraFilter

## SYNOPSIS

Returns information about a filter in JIRA

## SYNTAX

### ByFilterID (Default)

```powershell
Get-JiraFilter [-Id] <String[]> [-Credential <PSCredential>] [<CommonParameters>]
```

### ByInputObject

```powershell
Get-JiraFilter -InputObject <Object[]> [-Credential <PSCredential>]
 [<CommonParameters>]
```

### MyFavorite

```powershell
Get-JiraFilter -Favorite [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

This function returns information about a filter in JIRA, including the JQL
syntax of the filter, its owner, and sharing status.

This function is only capable of returning filters by their Filter ID.
This is a limitation of JIRA's REST API.

The easiest way to obtain the ID of a filter is to load the filter in the
"regular" Web view of JIRA, then copy the ID from the URL of the page.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraFilter -Id 12345
```

Gets a reference to filter ID 12345 from JIRA

### EXAMPLE 2

```powershell
$filterObject | Get-JiraFilter
```

Gets the information of a filter by providing a filter object


### EXAMPLE 3

```powershell
Get-JiraFilter -Favorite
```

Gets all filters makes as "favorite" by the user

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
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Favorite

Fetch all filters marked as favorite by the user

```yaml
Type: SwitchParameter
Parameter Sets: MyFavorite
Aliases: Favourite

Required: True
Position: Named
Default value: False
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

This cmdlet supports the common parameters: -Debug, -ErrorAction,
-ErrorVariable, -InformationAction, -InformationVariable, -OutVariable,
-OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters
(<http://go.microsoft.com/fwlink/?LinkID=113216>).

## INPUTS

### [JiraPS.Filter] / [String]

The filter to look up in JIRA. This can be a String (filter ID) or a JiraPS.Filter object.

## OUTPUTS

### [JiraPS.Filter]

## NOTES

This function requires either the `-Credential` parameter to be passed or
a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[New-JiraFilter](../New-JiraFilter/)

[Set-JiraFilter](../Set-JiraFilter/)

[Remove-JiraFilter](../Remove-JiraFilter/)

[Add-JiraFilterPermission](../Add-JiraFilterPermission/)

[Get-JiraFilterPermission](../Get-JiraFilterPermission/)

[Remove-JiraFilterPermission](../Remove-JiraFilterPermission/)
