---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Select-JiraConnection/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Select-JiraConnection/
---
# Select-JiraConnection

## SYNOPSIS

Select an active connection as the Jira default.

## SYNTAX

### Object (Default)

```powershell
Select-JiraConnection -Connection <AtlassianPS.Connection> [<CommonParameters>]
```

### Name

```powershell
Select-JiraConnection -Name <String> [<CommonParameters>]
```

### Id

```powershell
Select-JiraConnection -Id <Int32> [<CommonParameters>]
```

## DESCRIPTION

Select an active connection as the Jira default.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraConnection -Name work | Select-JiraConnection
```

Select by pipeline object.

### EXAMPLE 2

```powershell
Select-JiraConnection -Name work
```

Select by name.

### EXAMPLE 3

```powershell
Select-JiraConnection -Id $work.Id
```

Select by runtime ID.

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
