---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraConnection/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraConnection/
---
# Get-JiraConnection

## SYNOPSIS

List active Jira connections.

## SYNTAX

```powershell
Get-JiraConnection [-Name <String>] [-Id <Int32>] [-Default] [<CommonParameters>]
```

## DESCRIPTION

List active Jira connections.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraConnection
```

List active Jira connections.

### EXAMPLE 2

```powershell
Get-JiraConnection -Name work
```

Find the named connection.

### EXAMPLE 3

```powershell
Get-JiraConnection -Default
```

Inspect the current Jira default.

## PARAMETERS

### -Name

Friendly connection name, unique without case sensitivity within Jira.

```yaml
Type: String
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id

Runtime numeric connection ID, unique across products for the current shared runtime.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Default

Select the successful new connection as Jira default, or filter the listing to the current default. The first successful connection selects itself automatically; later connections leave an existing default unchanged unless this switch is supplied.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: None

Required: False
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
