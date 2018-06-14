---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraFilter/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Remove-JiraFilter/
---
# Remove-JiraFilter

## SYNOPSIS

Removes an existing filter.

## SYNTAX

### byInputObject (Default)

```powershell
Remove-JiraFilter [-InputObject] <JiraPS.Filter> [-WhatIf] [-Confirm] [<CommonParameters>]
```

### byId (Default)

```powershell
Remove-JiraFilter [-Id] <UInt32[]> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function will remove a filter from Jira.
Deleting a filter removed is permanently from Jira.

## EXAMPLES

### Example 1

```powershell
Remove-JiraFilter -InputObject (Get-JiraFilter "12345")
```

Removes the filter `12345` from Jira.

### Example 2

```powershell
$filter = Get-JiraFilter "12345", "98765"
Remove-JiraFilter -InputObject $filter
```

Removes two filters (`12345` and `98765`) from Jira.

### Example 3

```powershell
Get-JiraFilter "12345", "98765" | Remove-JiraFilter
```

Removes two filters (`12345` and `98765`) from Jira.

### Example 4

```powershell
Get-JiraFilter -Favorite | Remove-JiraFilter -Confirm
```

Asks for each favorite filter confirmation to delete it.

### Example 5

```powershell
$listOfFilters = 1,2,3,4
$listOfFilters | Remove-JiraFilter
```

Remove filters with id "1", "2", "3" and "4".

This input allows for the ID of the filters to be stored in an array and passed to
the command. (eg: `Get-Content` from a file with the ids)

## PARAMETERS

### -InputObject

Filter object to be deleted.

Object can be retrieved with `Get-JiraFilter`

```yaml
Type: JiraPS.Filter
Parameter Sets: ByInputObject
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Id

Id of the filter to be deleted.

Accepts integers over the pipeline.

```yaml
Type: UInt32[]
Parameter Sets: ById
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Credential

Credentials to use to connect to JIRA.  
If not specified, this function will use anonymous access.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

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

### [JiraPS.Filter]

## OUTPUTS

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraFilter](../Get-JiraFilter/)

[New-JiraFilter](../New-JiraFilter/)

[Set-JiraFilter](../Set-JiraFilter/)
