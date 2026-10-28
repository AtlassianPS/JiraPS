---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Set-JiraSession/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Set-JiraSession/
---
# Set-JiraSession

## SYNOPSIS

Compatibility entry point for Select-JiraConnection.

## SYNTAX

### Object (Default)

```powershell
Set-JiraSession -Connection <AtlassianPS.Connection> [<CommonParameters>]
```

### Name

```powershell
Set-JiraSession -Name <string> [<CommonParameters>]
```

### Id

```powershell
Set-JiraSession -Id <int> [<CommonParameters>]
```

## DESCRIPTION

Compatibility entry point for Select-JiraConnection.

This compatibility name uses the shared connection implementation.
It does not retain the v2 singleton or AtlassianPS.JiraPS.Session return type.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraConnection -Name work | Set-JiraSession
```

Use the canonical shared selection implementation.

### EXAMPLE 2

```powershell
Set-JiraSession -Name work
```

Select by name.

### EXAMPLE 3

```powershell
Set-JiraSession -Id $work.Id
```

Select by ID.

## PARAMETERS

### -Connection

Live shared connection for this operation.
Session is a compatibility alias.
The object must be active in this runspace and belong to Jira.

```yaml
Type: AtlassianPS.Connection
Parameter Sets: Object
Aliases: Session

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name

Friendly connection name, unique without case sensitivity within Jira.

```yaml
Type: String
Parameter Sets: Name
Aliases: None

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id

Runtime numeric connection ID, unique across products for the current shared runtime.

```yaml
Type: Int32
Parameter Sets: Id
Aliases: None

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

Supports standard PowerShell common parameters.

## INPUTS

### AtlassianPS.Connection

## OUTPUTS

### AtlassianPS.Connection

## NOTES

Connections belong to one runspace and are never persisted as profiles.

## RELATED LINKS

[Shared authentication](https://atlassianps.org/docs/AtlassianPS.Configuration/about/authentication.html)

[Jira authentication](https://atlassianps.org/docs/JiraPS/about/authentication.html)
