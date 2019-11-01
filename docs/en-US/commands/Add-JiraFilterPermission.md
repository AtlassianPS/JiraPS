---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Add-JiraFilterPermission/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Add-JiraFilterPermission/
---
# Add-JiraFilterPermission

## SYNOPSIS

Share a Filter with other users.

## SYNTAX

### ByInputObject (Default)

```powershell
Add-JiraFilterPermission [-Filter] <JiraPS.Filter> [-Type] <String>
 [[-Value] <String>] [[-Session] <PSObject>] [-WhatIf] [-Confirm]
  [<CommonParameters>]
```

### ById

```powershell
Add-JiraFilterPermission [-Id] <UInt32> [-Type] <String> [[-Value] <String>]
 [[-Session] <PSObject>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Share a Filter with other users, such as "Group", "Project", "ProjectRole",
"Authenticated" or "Global".

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

_The Id could be read from a file._

### Example 3

```powershell
Get-JiraFilter 12345 | Add-JiraFilterPermission -Type "Group" -Value "administrators"
```

Share Filter 12345 only with users in the administrators groups.

## PARAMETERS

### -Filter

Filter object to which the permission should be applied

```yaml
Type: JiraPS.Filter
Parameter Sets: ByInputObject
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Id

Id of the Filter to which the permission should be applied

_Id can be passed over the pipeline when reading from a file._

```yaml
Type: UInt32[]
Parameter Sets: ById
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Type

Type of the permission to add

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Group, Project, ProjectRole, Authenticated, Global

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
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
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Session

Session to use to connect to JIRA.  
If not specified, this function will use default session.
The name of a session, PSCredential object or session's instance itself is accepted to pass as value for the parameter.

```yaml
Type: psobject
Parameter Sets: (All)
Aliases: Credential

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

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

### [JiraPS.Filter]

## OUTPUTS

### [JiraPS.Filter]

## NOTES

This functions does not validate the input for `-Value`.
In case the value is invalid, unexpected or missing, the API will response with
an error.

This function requires either the `-Session` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraFilter](../Get-JiraFilter/)

[Get-JiraFilterPermission](../Get-JiraFilterPermission/)

[Remove-JiraFilterPermission](../Remove-JiraFilterPermission/)
