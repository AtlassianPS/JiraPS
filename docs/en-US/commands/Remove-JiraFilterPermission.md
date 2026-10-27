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

```powershell
Remove-JiraFilterPermission -Filter <AtlassianPS.JiraPS.Filter> [-Permission <AtlassianPS.JiraPS.FilterPermission[]>] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

## DESCRIPTION

Remove sharing permissions from a filter.
Pass a filter object or its numeric ID.
`FilterId` and `Id` are aliases for `Filter`.
`PermissionId` is an alias for `Permission`.
If `Permission` is omitted, the filter must contain permissions retrieved by `Get-JiraFilterPermission`.

## EXAMPLES

### Example 1

```powershell
Remove-JiraFilterPermission -FilterId 11822 -Permission 1111, 2222
```

Remove two share permissions from filter 11822.
Numeric IDs are converted to permission objects.

### Example 2

```powershell
Get-JiraFilter 11822 | Get-JiraFilterPermission | Remove-JiraFilterPermission
```

Remove all permissions of filter 11822

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

Username/password or compatible Cloud email/token as PSCredential.
Explicit input temporarily overrides the selected identity without inheriting cookies or changing the stored connection.
An empty credential fails; omitted input uses the selected connection.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
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

### -Permission

Permission objects or non-negative numeric permission IDs.
Zero is accepted; Jira determines whether the ID exists.
Permission objects must contain an ID.
If omitted, removes the permissions already present in the supplied filter object.

```yaml
Type: AtlassianPS.JiraPS.FilterPermission[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- PermissionId
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

### -Connection

Active Jira connection for this operation.
Session is a compatibility alias.
When omitted, the command uses the selected Jira default.
Use Get-JiraConnection -Name to resolve a named connection.

```yaml
Type: AtlassianPS.Connection
Parameter Sets: (All)
Aliases: Session

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable.
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.Filter

Pipe an AtlassianPS.JiraPS.Filter to remove all of its share permissions.

## OUTPUTS

### System.Object

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[Get-JiraFilter](../Get-JiraFilter/)

[Add-JiraFilterPermission](../Add-JiraFilterPermission/)

[Get-JiraFilterPermission](../Get-JiraFilterPermission/)
