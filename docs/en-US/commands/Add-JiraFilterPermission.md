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

Share a Filter with other users.

## SYNTAX

### ByInputObject (Default)

```powershell
Add-JiraFilterPermission [-Filter] <Filter> -Type <string> [-Value <string>]
 [-Credential <pscredential>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ById

```powershell
Add-JiraFilterPermission [-Id] <uint[]> -Type <string> [-Value <string>]
 [-Credential <pscredential>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Share a Filter with other users, such as "Group", "Project", "ProjectRole", "Authenticated" or "Global".

## EXAMPLES

### Example 1

```powershell
Add-JiraFilterPermission -Filter (Get-JiraFilter 12345) -Type "Global"
#-------
Add-JiraFilterPermission -Id 12345 -Type "Global"
```

Two methods of sharing Filter 12345 with everyone.

### Example 2

```powershell
12345 | Add-JiraFilterPermission -Type "Authenticated"
```

Share Filter 12345 with authenticated users.

The Id could be read from a file.

### Example 3

```powershell
Get-JiraFilter 12345 | Add-JiraFilterPermission -Type "Group" -Value "administrators"
```

Share Filter 12345 only with users in the administrators groups.

## PARAMETERS

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
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
Type: System.Management.Automation.PSCredential
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

Filter object to which the permission should be applied

```yaml
Type: JiraPS.Filter
DefaultValue: ''
SupportsWildcards: false
Aliases: []
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

### -Id

Id of the Filter to which the permission should be applied

_Id can be passed over the pipeline when reading from a file._

```yaml
Type: System.UInt32[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ById
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

Type of the permission to add

```yaml
Type: System.String
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

Value for the Type of the permission.

The Value differs per Type of the permission.

Here is a table to know what Value to provide:
|Type         |Value                |Source                                              |
|-------------|---------------------|----------------------------------------------------|
|Group        |Name of the Group    |Can be retrieved with `(Get-JiraGroup ...).Name`    |
|Project      |Id of the Project    |Can be retrieved with `(Get-JiraProject ...).Id`    |
|ProjectRole  |Id of the ProjectRole|Can be retrieved with `(Get-JiraProjectRole ...).Id`|
|Authenticated| **must be null**    |                                                    |
|Global       | **must be null**    |                                                    |

```yaml
Type: System.String
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
Type: System.Management.Automation.SwitchParameter
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

### JiraPS.Filter


### System.UInt32[]

## OUTPUTS

### JiraPS.Filter

## NOTES

This functions does not validate the input for `-Value`.
In case the value is invalid, unexpected or missing, the API will response with
an error.

This function requires either the `-Credential` parameter to be passed or
a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraFilter](../Get-JiraFilter/)

[Get-JiraFilterPermission](../Get-JiraFilterPermission/)

[Remove-JiraFilterPermission](../Remove-JiraFilterPermission/)
