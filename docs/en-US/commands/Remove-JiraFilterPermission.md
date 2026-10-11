---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraFilterPermission/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Remove-JiraFilterPermission/
---
# Remove-JiraFilterPermission

## SYNOPSIS

Remove a permission of a Filter

## SYNTAX

```powershell
Remove-JiraFilterPermission [-Filter] <AtlassianPS.JiraPS.Filter> [[-PermissionId] <AtlassianPS.JiraPS.FilterPermission[]>] [-Credential <pscredential>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Remove sharing permissions from a filter.
Pass a filter object or its numeric ID.
`FilterId` and `Id` remain aliases for `Filter`.
If `PermissionId` is omitted, the filter must contain permissions retrieved by `Get-JiraFilterPermission`.

## EXAMPLES

### Example 1

```powershell
Remove-JiraFilterPermission -FilterId 11822 -PermissionId 1111, 2222
```

Remove two share permissions of Filter with ID '11822'

### Example 2

```powershell
Get-JiraFilter 11822 | Get-JiraFilterPermission | Remove-JiraFilterPermission
```

Remove all permissions of Filter 11822

## PARAMETERS

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
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

### -Credential

Credentials to use to connect to JIRA.
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

### -Filter

Filter object or positive numeric filter ID from which to remove permissions.

```yaml
Type: AtlassianPS.JiraPS.Filter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- FilterId
- Id
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PermissionId

Permission objects or non-negative numeric permission IDs.
Zero retains the previous numeric parameter behavior; Jira determines whether the ID exists.
Permission objects must contain an ID.
If omitted, removes the permissions already present in the supplied filter object.

```yaml
Type: AtlassianPS.JiraPS.FilterPermission[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.Filter

Pipe a AtlassianPS.JiraPS.Filter to remove all of its share permissions.

## OUTPUTS

### System.Object

## NOTES

This function requires either the `-Credential` parameter to be passed or
a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraFilter](../Get-JiraFilter/)

[Add-JiraFilterPermission](../Add-JiraFilterPermission/)

[Get-JiraFilterPermission](../Get-JiraFilterPermission/)
