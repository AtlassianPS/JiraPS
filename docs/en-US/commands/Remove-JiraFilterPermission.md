---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraFilterPermission/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Remove-JiraFilterPermission/
---
# Remove-JiraFilterPermission

## SYNOPSIS

Remove a permission of a Filter

## SYNTAX

### ByFilterId (Default)

```powershell
Remove-JiraFilterPermission [-Filter] <JiraPS.Filter> [[-Session] <PSObject>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ByFilterObject

```powershell
Remove-JiraFilterPermission [-FilterId] <UInt32> [-PermissionId] <UInt32[]>
 [[-Session] <PSObject>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Remove a sharing permission of a Filter.

## EXAMPLES

### Example 1

```powershell
Remove-JiraFilterPermission -FilterId 11822 -PermissionId 1111, 2222
```

Remove two share permissions of Filter with ID '11822'

### Example 1

```powershell
Get-JiraFilter 11822 | Get-JiraFilterPermission | Remove-JiraFilterPermission
```

Remove all permissions of Filter 11822

## PARAMETERS

### -Filter

Object of the Filter from which to remove a permission.

```yaml
Type: JiraPS.Filter
Parameter Sets: ByFilterObject
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -FilterId

Id of the Filter from which to remove a permission.

```yaml
Type: UInt32
Parameter Sets: ByFilterId
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -PermissionId

List of id's of the permissions to remove.

```yaml
Type: UInt32[]
Parameter Sets: ByFilterId
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
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
Position: 1
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

### System.Object

## OUTPUTS

### System.Object

## NOTES

This function requires either the `-Session` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraFilter](../Get-JiraFilter/)

[Add-JiraFilterPermission](../Add-JiraFilterPermission/)

[Get-JiraFilterPermission](../Get-JiraFilterPermission/)
