---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraStatus/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraStatus/
---
# Get-JiraStatus

## SYNOPSIS

Returns issue status information from Jira.

## SYNTAX

### _All (Default)

```powershell
Get-JiraStatus [-Credential <pscredential>] [<CommonParameters>]
```

### _Search

```powershell
Get-JiraStatus [-Status] <string[]> [-Credential <pscredential>] [<CommonParameters>]
```

## DESCRIPTION

This function returns Jira status objects.
Use it to retrieve all available statuses or to query one or more statuses by id or name.
`-IdOrName` is provided as an alias for `-Status`.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraStatus
```

Returns all available statuses.

### EXAMPLE 2

```powershell
Get-JiraStatus -Status 1
```

Returns the status with id 1.

### EXAMPLE 3

```powershell
Get-JiraStatus -Status Open
```

Returns the status named Open.

## PARAMETERS

### -Credential

Credentials to use to connect to Jira.
If not specified, this function uses anonymous access.

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

### -Status

One or more statuses to retrieve.
Each value can be a status id (for example, `1`) or a status name (for example, `Open`).

```yaml
Type: String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- IdOrName
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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable.
For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### String

Values passed to `-Status` can be provided through the pipeline.

## OUTPUTS

### JiraPS.Status

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent Jira session.
See `New-JiraSession` for more details.
If neither are supplied, this function runs with anonymous access to Jira.

## RELATED LINKS

[Get-JiraIssue](../Get-JiraIssue/)
