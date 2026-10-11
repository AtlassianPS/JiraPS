---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueType/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueType/
---
# Get-JiraIssueType

## SYNOPSIS

Returns information about the available issue type in Jira.

## SYNTAX

### _All (Default)

```powershell
Get-JiraIssueType [-Force] [-Credential <pscredential>] [<CommonParameters>]
```

### _Search

```powershell
Get-JiraIssueType [-IssueType] <AtlassianPS.JiraPS.IssueType[]> [-Force] [-Credential <pscredential>]
 [<CommonParameters>]
```

## DESCRIPTION

This function retrieves all the available IssueType on the Jira server an returns them as `AtlassianPS.JiraPS.IssueType`.

This function can restrict the output to a subset of the available IssueTypes if told so.

Results are cached for 60 minutes to improve performance.
Use `-Force` to bypass the cache and fetch fresh data.

## EXAMPLES

### Example 1

```powershell
Get-JiraIssueType
```

This example returns all the IssueTypes on the Jira server.

### Example 2

```powershell
Get-JiraIssueType -IssueType 'Bug'
```

This example returns only the IssueType "Bug".

### Example 3

```powershell
Get-JiraIssueType -IssueType 'Bug','Task','4'
```

This example return the information about the IssueType named "Bug" and "Task" and with ID "4".

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

### -Force

Bypass the cache and fetch fresh data from the server.

```yaml
Type: SwitchParameter
DefaultValue: False
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

### -IssueType

Issue type objects, IDs or wildcard issue type names.
An object with an ID selects that exact issue type.

```yaml
Type: AtlassianPS.JiraPS.IssueType[]
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

### AtlassianPS.JiraPS.IssueType

Pipe an issue type object to retrieve its current details.

### System.String

Pipe an issue type name or ID.

### System.Int64

Pipe a numeric issue type ID.

## OUTPUTS

### AtlassianPS.JiraPS.IssueType

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent Jira session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to Jira.

## RELATED LINKS

[Get-JiraIssue](../Get-JiraIssue/)
