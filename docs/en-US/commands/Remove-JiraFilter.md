---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraFilter/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Remove-JiraFilter/
---
# Remove-JiraFilter

## SYNOPSIS

Removes an existing filter.

## SYNTAX

```powershell
Remove-JiraFilter [-InputObject] <AtlassianPS.JiraPS.Filter[]> [-Credential <pscredential>] [-Connection <AtlassianPS.Connection>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function will remove a filter from Jira.
Deleting a filter permanently removes it from Jira.

## EXAMPLES

### Example 1

```powershell
Remove-JiraFilter -InputObject (Get-JiraFilter '12345')
```

Removes the filter `12345` from Jira.

### Example 2

```powershell
$filter = Get-JiraFilter '12345', '98765'
Remove-JiraFilter -InputObject $filter
```

Removes two filters (`12345` and `98765`) from Jira.

### Example 3

```powershell
Get-JiraFilter '12345', '98765' | Remove-JiraFilter
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

Remove filters with ID "1", "2", "3" and "4".

This input allows for the ID of the filters to be stored in an array and passed to the command. (eg: `Get-Content` from a file with the ids)

## PARAMETERS

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Credential

Username/password or compatible Cloud email/token as PSCredential.
Explicit input temporarily overrides the selected identity without inheriting cookies or changing the stored connection.
An empty credential fails; omitted input uses the selected connection.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject

Filter objects or positive numeric filter IDs to delete.
Accepts numeric strings and pipeline input.
`Id` and `FilterId` are aliases for `InputObject`.

```yaml
Type: AtlassianPS.JiraPS.Filter[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
- FilterId
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Connection

Active Jira connection for this operation.
Session is a compatibility alias.
When omitted, the command uses the selected Jira default.
Use Get-JiraConnection -Name to resolve a named connection.

```yaml
Type: AtlassianPS.Connection
Parameter Sets: (All)
Aliases: Session

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable.
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.Filter


## OUTPUTS

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraFilter](../Get-JiraFilter/)

[New-JiraFilter](../New-JiraFilter/)

[Set-JiraFilter](../Set-JiraFilter/)
