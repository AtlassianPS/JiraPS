---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraSession/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraSession/
---
# Get-JiraSession

## SYNOPSIS

List Jira connections through the legacy command name.

## SYNTAX

```powershell
Get-JiraSession [[-Name] <string>] [[-Id] <int>] [-Default] [<CommonParameters>]
```

## DESCRIPTION

List Jira connections through the legacy command name.

This compatibility name uses the shared connection implementation.
It does not retain the v2 singleton or AtlassianPS.JiraPS.Session return type.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraSession
```

List all Jira connections.
The output type is AtlassianPS.Connection.

## PARAMETERS

### -Name

Friendly connection name, unique without case sensitivity within Jira.

```yaml
Type: String
Parameter Sets: (All)
Aliases: None

Required: False
Position: 0
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
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Default

Return only the current Jira default connection.

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

### None

## OUTPUTS

### AtlassianPS.Connection

## NOTES

Connections belong to one runspace and are never persisted as profiles.

## RELATED LINKS

[Shared authentication](https://atlassianps.org/docs/AtlassianPS.Configuration/about/authentication.html)

[Jira authentication](https://atlassianps.org/docs/JiraPS/about/authentication.html)
