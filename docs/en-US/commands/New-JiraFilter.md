---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/New-JiraFilter/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/New-JiraFilter/
---
# New-JiraFilter

## SYNOPSIS

Create a new Jira filter.

## SYNTAX

```powershell
New-JiraFilter -Name <String> [-Description <String>] -JQL <String> [-Favorite] [-Session <PSObject>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Create a new Jira filter.

## EXAMPLES

### Example 1

```powershell
New-JiraFilter -Name "My Bugs" -JQL "type = Bug and assignee = currentuser()"
```

Creates a new filter named "My Bugs"

### Example 2

```powershell
New-JiraFilter -Name "My Bugs" -JQL "type = Bug and assignee = currentuser()" -Favorite
```

Creates a new filter named "My Bugs" and stores it as favorite

### Example 3

```powershell
$splatNewFilter = @{
    Name = "My Bugs"
    Description = "collections of bugs assigned to me"
    JQL = "type = Bug and assignee = currentuser()"
    Favorite = $true
}
New-JiraFilter @splatNewFilter
```

Creates a new filter named "My Bugs" using splatting

## PARAMETERS

### -Name

Name of the filter.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Description

Description for the filter.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -JQL

JQL string which the filter uses for matching issues.

More about JQL at <https://confluence.atlassian.com/display/JIRA/Advanced+Searching>

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Favorite

Make this new filter a favorite of the user.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: Favourite

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
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
Position: 2
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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.String]

## OUTPUTS

### [JiraPS.Filter]

## NOTES

This function requires either the `-Session` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraFilter](../Get-JiraFilter/)

[Set-JiraFilter](../Set-JiraFilter/)

[Remove-JiraFilter](../Remove-JiraFilter/)
