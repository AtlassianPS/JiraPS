---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Disconnect-Jira/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Disconnect-Jira/
---
# Disconnect-Jira

## SYNOPSIS

Disconnect Jira locally and invalidate retained handles.

## SYNTAX

### Default (Default)

```powershell
Disconnect-Jira [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Object

```powershell
Disconnect-Jira -Connection <AtlassianPS.Connection> [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Name

```powershell
Disconnect-Jira -Name <string> [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Id

```powershell
Disconnect-Jira -Id <int> [-WhatIf] [-Confirm] [<CommonParameters>]
```

### All

```powershell
Disconnect-Jira -All [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Disconnect Jira locally and invalidate retained handles.

## EXAMPLES

### EXAMPLE 1

```powershell
$work | Disconnect-Jira
```

Invalidate one retained handle.

### EXAMPLE 2

```powershell
Disconnect-Jira
```

Disconnect only the Jira default.

### EXAMPLE 3

```powershell
Disconnect-Jira -All
```

Disconnect all Jira connections.

### EXAMPLE 4

```powershell
Disconnect-Jira -Name work
```

Disconnect by name.

### EXAMPLE 5

```powershell
Disconnect-Jira -Id $work.Id
```

Disconnect by ID.

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

### -All

Disconnect every Jira connection.
Without a selector or All, Disconnect-Jira removes only the current Jira default.

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
