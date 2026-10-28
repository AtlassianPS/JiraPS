---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Set-JiraFilter/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Set-JiraFilter/
---
# Set-JiraFilter

## SYNOPSIS

Make changes to an existing filter.

## SYNTAX

```powershell
Set-JiraFilter [-InputObject] <AtlassianPS.JiraPS.Filter> [[-Name] <string>] [[-Description] <string>] [[-JQL] <string>] [[-Favorite] <bool>] [[-Credential] <pscredential>] [[-Connection] <AtlassianPS.Connection>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Make changes to an existing filter.

If no changing parameter is provided, no action will be performed.

## EXAMPLES

### Example 1

```powershell
Set-JiraFilter -InputObject (Get-JiraFilter '12345') -Name 'NewName'
```

Changes the name of filter "12345" to "NewName"

### Example 2

```powershell
$filterData = @{
    InputObject = Get-JiraFilter '12345'
    Description = 'A new description'
    JQL = 'project = TV AND type = Bug'
    Favorite = $true
}
Set-JiraFilter @filterData
```

Changes the description and JQL of filter "12345" and make it a favorite

### Example 3

```powershell
Get-JiraFilter -Favorite |
    Where name -notlike 'My*' |
    Set-JiraFilter -Favorite $false
```

Remove all favorite filters where the name does not start with "My"

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
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description

New value for the filter's Description.

Can be an empty string.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Favorite

Boolean flag if the filter should be marked as favorite for the user.

```yaml
Type: Boolean
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Favourite
ParameterSets:
- Name: (All)
  Position: 4
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -InputObject

Filter object to be changed.

Object can be retrieved with `Get-JiraFilter`.

```yaml
Type: AtlassianPS.JiraPS.Filter
DefaultValue: ''
SupportsWildcards: false
Aliases: []
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

### -JQL

New value for the filter's JQL string which the filter uses for matching issues.

More about JQL at <https://confluence.atlassian.com/display/Jira/Advanced+Searching>.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 3
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Name

The new filter name.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
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
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable.
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.Filter / String

## OUTPUTS

### AtlassianPS.JiraPS.Filter

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraFilter](../Get-JiraFilter/)

[New-JiraFilter](../New-JiraFilter/)

[Remove-JiraFilter](../Remove-JiraFilter/)
