---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Move-JiraVersion/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Move-JiraVersion/
---
# Move-JiraVersion

## SYNOPSIS

Moves an existing Version in JIRA

## SYNTAX

### ByAfter (Default)

```powershell
Move-JiraVersion [-Version] <JiraPS.Version> [-After] <JiraPS.Version> [[-Session] <PSObject>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ByPosition

```powershell
Move-JiraVersion [-Version] <JiraPS.Version> [-Position] <String> [[-Session] <PSObject>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function moves the Version for an existing Project in JIRA.
Moving the Version modifies the order/sequence of the Version in relation to other Versions.

## EXAMPLES

### EXAMPLE 1

```powershell
Move-JiraVersion -Version 10 -After 9
```

This example moves the Version with ID 10 after the Version with ID 9.

### EXAMPLE 2

```powershell
Move-JiraVersion -Version $myVersionObject -After $otherVersionObject
```

This example moves the Version object after the other Version object.

### EXAMPLE 3

```powershell
Move-JiraVersion -Version $myVersionObject -Position Earliest
```

This example moves the Version object to the earliest position.

## PARAMETERS

### -Version

Version Object or ID to move.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True
Accept wildcard characters: False
```

### -Position

The new Position for the Version

```yaml
Type: String
Parameter Sets: ByPosition
Aliases:
Accepted values: First, Last, Earlier, Later

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -After

Version Object or ID to move Version after.

```yaml
Type: Object
Parameter Sets: ByAfter
Aliases:

Required: True
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [JiraPS.Version]

## NOTES

This function requires either the `-Session` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraVersion](../Get-JiraVersion/)

[New-JiraVersion](../New-JiraVersion/)

[Remove-JiraVersion](../Remove-JiraVersion/)

[Set-JiraVersion](../Set-JiraVersion/)
