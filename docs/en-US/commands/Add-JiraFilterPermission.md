---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Add-JiraFilterPermission/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Add-JiraFilterPermission/
---
# Add-JiraFilterPermission

## SYNOPSIS

Share a filter with other users.

## SYNTAX

```powershell
Add-JiraFilterPermission [-Filter] <AtlassianPS.JiraPS.Filter[]> -Type <string> [-Value <string>]
 [-Credential <pscredential>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Share a filter with a group, project role, authenticated users or everyone.
Use `Type` to choose the permission and `Value` to identify the group, project or role.

## EXAMPLES

### Example 1

```powershell
Add-JiraFilterPermission -Filter (Get-JiraFilter 12345) -Type 'Global'
# Or use the ID directly.
Add-JiraFilterPermission -Id 12345 -Type 'Global'
```

Two methods of sharing filter 12345 with everyone.

### Example 2

```powershell
12345 | Add-JiraFilterPermission -Type 'Authenticated'
```

Share filter 12345 with authenticated users.

The ID can be read from a file.

### Example 3

```powershell
Get-JiraFilter 12345 | Add-JiraFilterPermission -Type 'Group' -Value 'administrators'
```

Share filter 12345 only with users in the administrators group.

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

### -Filter

Filter objects or positive numeric filter IDs to share.
Accepts numeric strings and pipeline input.
`Id` is an alias for `Filter`.

```yaml
Type: AtlassianPS.JiraPS.Filter[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
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

### -Type

Type of the permission to add.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues:
- Group
- Project
- ProjectRole
- Authenticated
- Global
HelpMessage: ''
```

### -Value

Value associated with the permission type.

The required value depends on the permission type:

|Type         |Value                |Source                                              |
|-------------|---------------------|----------------------------------------------------|
|Group        |Group name    |Use the known group name directly; avoid relying on `Get-JiraGroup` for Data Center-only resolution.|
|Project      |Project ID    |Can be retrieved with `(Get-JiraProject ...).Id`    |
|ProjectRole  |Project role ID|Use the ID at the end of the role URL in `(Get-JiraProject ...).Roles`|
|Authenticated| **must be null**    |                                                    |
|Global       | **must be null**    |                                                    |

```yaml
Type: String
DefaultValue: ''
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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable.
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.Filter


## OUTPUTS

### AtlassianPS.JiraPS.Filter

## NOTES

The command sends `Value` to Jira without validating it locally.
Jira reports an error if the value is invalid or missing.

This function requires either the `-Credential` parameter to be passed or a persistent Jira session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to Jira.

## RELATED LINKS

[Get-JiraFilter](../Get-JiraFilter/)

[Get-JiraFilterPermission](../Get-JiraFilterPermission/)

[Remove-JiraFilterPermission](../Remove-JiraFilterPermission/)
