---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Set-JiraFilter/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Set-JiraFilter/
---
# Set-JiraFilter

## SYNOPSIS

Make changes to an existing Filter.

## SYNTAX

```powershell
Set-JiraFilter [-InputObject] <Object> [[-Name] <String>] [[-Description] <String>] [[-JQL] <String>]
 [-Favorite] [[-Session] <PSObject>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Make changes to an existing Filter.

If no changing parameter is provided, no action will be performed.

## EXAMPLES

### Example 1

```powershell
Set-JiraFilter -InputObject (Get-JiraFilter "12345") -Name "NewName"
```

Changes the name of filter "12345" to "NewName"

### Example 2

```powershell
$filterData = @{
    InputObject = Get-JiraFilter "12345"
    Description = "A new description"
    JQL = "project = TV AND type = Bug"
    Favorite = $true
}
Set-JiraFilter @filterData
```

Changes the description and JQL of filter "12345" and make it a favorite

### Example 3

```powershell
Get-JiraFilter -Favorite |
    Where name -notlike "My*" |
    Set-JiraFilter -Favorite $false
```

Remove all favorite filters where the name does not start with "My"

## PARAMETERS

### -InputObject

Filter object to be changed.

Object can be retrieved with `Get-JiraFilter`

```yaml
Type: JiraPS.Filter
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name

New value for the filter's Name.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description

New value for the filter's Description.

Can be an empty string.

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

### -JQL

New value for the filter's JQL string which the filter uses for matching issues.

More about JQL at <https://confluence.atlassian.com/display/JIRA/Advanced+Searching>

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Favorite

Boolean flag if the filter should be marked as favorite for the user.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases: Favourite

Required: False
Position: Named
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

### [JiraPS.Filter] / [String]

## OUTPUTS

### [JiraPS.Filter]

## NOTES

This function requires either the `-Session` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraFilter](../Get-JiraFilter/)

[New-JiraFilter](../New-JiraFilter/)

[Remove-JiraFilter](../Remove-JiraFilter/)
