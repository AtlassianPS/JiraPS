---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Format-Jira

## SYNOPSIS
Converts an object into a table formatted according to JIRA's markdown syntax

## SYNTAX

```
Format-Jira [[-Property] <Object[]>] -InputObject <PSObject[]>
```

## DESCRIPTION
This function converts a PowerShell object into a table using JIRA's markdown syntax.
This can then be added to a JIRA issue description or comment.

Like the native Format-* cmdlets, this is a destructive operation, so as always, remember to "filter left, format right!"

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-Process | Format-Jira | Add-JiraIssueComment -Issue TEST-001
```

This example illustrates converting the output from Get-Process into a JIRA table, which is then added as a comment to issue TEST-001.

### -------------------------- EXAMPLE 2 --------------------------
```
Get-Process chrome | Format-Jira Name,Id,VM
```

This example obtains all Google Chrome processes, then creates a JIRA table with only the Name,ID, and VM properties of each object.

## PARAMETERS

### -Property
List of properties to display.
If omitted, only the default properties will be shown.

To display all properties, use -Property *.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject
Object to format.

```yaml
Type: PSObject[]
Parameter Sets: (All)
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

## INPUTS

### [System.Object[]] - accepts any Object via pipeline

## OUTPUTS

### [System.String]

## NOTES
This is a destructive operation, since it permanently reduces InputObjects to Strings. 
Remember to "filter left, format right."

## RELATED LINKS

