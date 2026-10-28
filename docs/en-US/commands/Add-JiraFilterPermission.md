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
 [-Connection <AtlassianPS.Connection>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Share a filter with a group, project role, authenticated users or everyone.
Use `Type` to choose the permission and `Value` to identify the group, project or role.
Returns the typed permission records Jira supplies.

## EXAMPLES

### Example 1: Share a filter with everyone

```powershell
Add-JiraFilterPermission -Filter 12345 -Type Global

# Or pass a filter object.
Add-JiraFilterPermission -Filter (Get-JiraFilter -Filter 12345) -Type Global
```

Share filter 12345 with everyone using its ID or a filter object.
Each call returns the permission records Jira supplies.

### Example 2: Share a piped filter ID with authenticated users

```powershell
12345 | Add-JiraFilterPermission -Type Authenticated
```

Share filter 12345 with authenticated users.
Filter IDs can also come from a file or another command.

### Example 3: Share a filter with a group

```powershell
Get-JiraFilter -Filter 12345 |
    Add-JiraFilterPermission -Type Group -Value 'administrators'
```

Add sharing permission for users in the administrators group.
Pipe the filter object returned by Get-JiraFilter into Add-JiraFilterPermission.

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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.Filter[]

## OUTPUTS

### AtlassianPS.JiraPS.FilterPermission

## NOTES

The command sends `Value` to Jira without validating it locally.
Jira reports an error if the value is invalid or missing.

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraFilter](../Get-JiraFilter/)

[Get-JiraFilterPermission](../Get-JiraFilterPermission/)

[Remove-JiraFilterPermission](../Remove-JiraFilterPermission/)
