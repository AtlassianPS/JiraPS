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

Remove a permission of a filter.

## SYNTAX

### Permission (Default)

```
Remove-JiraFilterPermission [-Filter] <AtlassianPS.JiraPS.Filter> [-Permission] <AtlassianPS.JiraPS.FilterPermission[]>
 [-Connection <AtlassianPS.Connection>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### All

```
Remove-JiraFilterPermission [-Filter] <AtlassianPS.JiraPS.Filter> -All [-Connection <AtlassianPS.Connection>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

Removes explicitly selected permissions, or every current permission when All is supplied.
All fetches current permissions instead of trusting embedded filter snapshots.
Every permission is validated before deletion begins.

## EXAMPLES

### Example 1

```powershell
Remove-JiraFilterPermission -Filter 12345 -Permission 1111
```

Remove one explicitly selected permission.

### Example 2

```powershell
Remove-JiraFilterPermission -Filter 12345 -All -Confirm:$false
```

Fetch and remove every current permission with explicit bulk intent.

## PARAMETERS

### -All

Fetch and remove every current permission on the filter.
Cannot be combined with Permission.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: All
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

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

### -Connection

Active Jira connection for this operation.
When omitted, the command uses the selected Jira default.
Create connections with Connect-Jira; resolve names with Get-JiraConnection -Name.

```yaml
Type: AtlassianPS.Connection
DefaultValue: None
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

Filter identifiers or typed filter objects.
Pipe filter objects to this parameter.

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

### -Permission

Explicit non-negative permission IDs or typed permission objects.
Omitting this parameter requires All.

```yaml
Type: AtlassianPS.JiraPS.FilterPermission[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- PermissionId
ParameterSets:
- Name: Permission
  Position: 1
  IsRequired: true
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

## OUTPUTS

### System.Object

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraFilter](../Get-JiraFilter/)

[Add-JiraFilterPermission](../Add-JiraFilterPermission/)

[Get-JiraFilterPermission](../Get-JiraFilterPermission/)
