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
Get-JiraProject [-Credential <pscredential>] [<CommonParameters>]
```

### _Search

```powershell
Get-JiraProject [-Project] <AtlassianPS.JiraPS.Project[]> [-Credential <pscredential>] [<CommonParameters>]
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

Credentials to use to connect to Jira.
If not specified, this function will use anonymous access.

```yaml
Type: PSCredential
DefaultValue: '[System.Management.Automation.PSCredential]::Empty'
SupportsWildcards: false
Aliases: []
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable.
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### AtlassianPS.JiraPS.Project

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent Jira session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to Jira.

Remaining operations for `project` have not yet been implemented in the module.

## RELATED LINKS
