---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraFilter/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraFilter/
---
# Get-JiraFilter

## SYNOPSIS

Returns information about a filter in Jira.

## SYNTAX

### ByInputObject (Default)

```powershell
Get-JiraFilter [-InputObject] <AtlassianPS.JiraPS.Filter[]> [-Credential <pscredential>] [<CommonParameters>]
```

### MyFavorite

```powershell
Get-JiraFilter -Favorite [-Credential <pscredential>] [<CommonParameters>]
```

## DESCRIPTION

This function returns information about a filter in Jira, including the JQL syntax of the filter, its owner, and sharing status.

This function is only capable of returning filters by their filter ID.
This is a limitation of Jira's REST API.

The easiest way to obtain the ID of a filter is to load the filter in the "regular" Web view of Jira, then copy the ID from the URL of the page.

## EXAMPLES

### Example 1

```powershell
Get-JiraFilter -Id 12345
```

Gets a reference to filter ID 12345 from Jira

### Example 2

```powershell
$filterObject | Get-JiraFilter
```

Gets the information of a filter by providing a filter object

### Example 3

```powershell
Get-JiraFilter -Favorite
```

Gets all filters makes as "favorite" by the user

## PARAMETERS

### -Credential

Credentials to use to connect to Jira.
If not specified, this function will use anonymous access.

```yaml
Type: PSCredential
DefaultValue: '[System.Management.Automation.PSCredential]::Empty'
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Favorite

Fetch all filters marked as favorite by the user.

```yaml
Type: SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases:
- Favourite
ParameterSets:
- Name: MyFavorite
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -InputObject

Filter objects or positive numeric filter IDs to retrieve.
Accepts numeric strings and pipeline input.
`Id` is an alias for `InputObject`.

```yaml
Type: AtlassianPS.JiraPS.Filter[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
ParameterSets:
- Name: ByInputObject
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable.
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.Filter / String

The filter to look up in Jira.
This can be a String (filter ID) or an AtlassianPS.JiraPS.Filter object.

## OUTPUTS

### AtlassianPS.JiraPS.Filter

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent Jira session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to Jira.

## RELATED LINKS

[New-JiraFilter](../New-JiraFilter/)

[Set-JiraFilter](../Set-JiraFilter/)

[Remove-JiraFilter](../Remove-JiraFilter/)

[Add-JiraFilterPermission](../Add-JiraFilterPermission/)

[Get-JiraFilterPermission](../Get-JiraFilterPermission/)

[Remove-JiraFilterPermission](../Remove-JiraFilterPermission/)
