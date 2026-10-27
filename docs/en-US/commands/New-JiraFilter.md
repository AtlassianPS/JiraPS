---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/New-JiraFilter/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/New-JiraFilter/
---
# New-JiraFilter

## SYNOPSIS

Create a new Jira filter.

## SYNTAX

```powershell
New-JiraFilter -Name <String> [-Description <String>] -JQL <String> [-Favorite] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
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

### -Description

Description for the filter.

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
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Favorite

Make this new filter a favorite of the user.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Favourite
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -JQL

JQL string which the filter uses for matching issues.

More about JQL at <https://confluence.atlassian.com/display/JIRA/Advanced+Searching>

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 2
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Name

Friendly connection name, unique without case sensitivity within Jira.

```yaml
Type: String
Parameter Sets: (All)
Aliases: None

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String


## OUTPUTS

### AtlassianPS.JiraPS.Filter

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraFilter](../Get-JiraFilter/)

[Set-JiraFilter](../Set-JiraFilter/)

[Remove-JiraFilter](../Remove-JiraFilter/)
