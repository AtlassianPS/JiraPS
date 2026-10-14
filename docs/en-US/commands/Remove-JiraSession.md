---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraSession/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Remove-JiraSession/
---
# Remove-JiraSession

## SYNOPSIS

Disconnect Jira through the legacy command name.

## SYNTAX

### Default (Default)

```powershell
Remove-JiraSession [<CommonParameters>]
```

### Object

```powershell
Remove-JiraSession -Connection <AtlassianPS.Connection> [<CommonParameters>]
```

### Name

```powershell
Remove-JiraSession -Name <String> [<CommonParameters>]
```

### Id

```powershell
Remove-JiraSession -Id <Int32> [<CommonParameters>]
```

### All

```powershell
Remove-JiraSession -All [<CommonParameters>]
```

## DESCRIPTION

Disconnect Jira through the legacy command name.

This compatibility name uses the shared connection implementation.
It does not retain the v2 singleton or AtlassianPS.JiraPS.Session return type.

## EXAMPLES

### EXAMPLE 1

```powershell
$work | Remove-JiraSession
```

Disconnect through the compatibility command.

### EXAMPLE 2

```powershell
Remove-JiraSession
```

Disconnect the Jira default.

### EXAMPLE 3

```powershell
Remove-JiraSession -All
```

Disconnect every Jira connection.

### EXAMPLE 4

```powershell
Remove-JiraSession -Name work
```

Disconnect a named Jira connection.

### EXAMPLE 5

```powershell
Remove-JiraSession -Id $work.Id
```

Disconnect by ID.

## PARAMETERS

### -Connection

Live shared connection for this operation. Session is a compatibility alias. The object must be active in this runspace and belong to Jira.

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

### -All

Disconnect every Jira connection. Without a selector or All, Disconnect-Jira removes only the current Jira default.

```yaml
Type: SwitchParameter
Parameter Sets: All
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

## NOTES

Connections belong to one runspace and are never persisted as profiles.

## RELATED LINKS

[Shared authentication](https://atlassianps.org/docs/AtlassianPS.Configuration/about/authentication.html)

[Jira authentication](https://atlassianps.org/docs/JiraPS/about/authentication.html)
