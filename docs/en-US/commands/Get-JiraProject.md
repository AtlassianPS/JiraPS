---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraProject/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraProject/
---
# Get-JiraProject

## SYNOPSIS

Returns a project from Jira.

## SYNTAX

### _All (Default)

```powershell
Get-JiraProject [-Credential <pscredential>] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

### _Search

```powershell
Get-JiraProject [-Project] <AtlassianPS.JiraPS.Project[]> [-Credential <pscredential>] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

## DESCRIPTION

This function returns information regarding a specified project from Jira.

If the project parameter is not supplied, it will return information about all projects the given user is authorized to view.

The `-Project` parameter will accept either a project ID or a project key.

## EXAMPLES

### Example 1

```powershell
Get-JiraProject -Project TEST -Credential $cred
```

Returns information about the project TEST

### Example 2

```powershell
Get-JiraProject 2 -Credential $cred
```

Returns information about the project with ID 2

### Example 3

```powershell
Get-JiraProject
```

Returns information about all projects the user is authorized to view

## PARAMETERS

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

### -Project

The project ID or project key of a project to search.

```yaml
Type: AtlassianPS.JiraPS.Project[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: _Search
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
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

## OUTPUTS

### AtlassianPS.JiraPS.Project

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

Remaining operations for `project` have not yet been implemented in the module.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)
