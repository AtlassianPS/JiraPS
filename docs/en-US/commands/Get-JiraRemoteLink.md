---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraRemoteLink/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraRemoteLink/
---
# Get-JiraRemoteLink

## SYNOPSIS

Returns a remote link from a Jira issue

## SYNTAX

```powershell
Get-JiraRemoteLink [-Issue] <Object> [[-LinkId] <int>] [[-Credential] <pscredential>]
 [<CommonParameters>]
```

## DESCRIPTION

This function returns information on remote links from a  JIRA issue.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraRemoteLink -Issue TEST-001 -Credential $cred
```

Returns information about all remote links from the issue "TEST-001"

### EXAMPLE 2

```powershell
Get-JiraRemoteLink -Issue TEST-001 -LinkId 100000 -Credential $cred
```

Returns information about a specific remote link from the issue "TEST-001"

## PARAMETERS

### -Credential

Credentials to use to connect to JIRA.
If not specified, this function will use anonymous access.

```yaml
Type: PSCredential
DefaultValue: '[System.Management.Automation.PSCredential]::Empty'
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

### -Issue

The Issue to search for link.

Can be a `JiraPS.Issue` object, issue key, or internal issue ID.

```yaml
Type: Object
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Key
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -LinkId

Get a single link by it's id.

```yaml
Type: Int32
DefaultValue: 0
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### JiraPS.Issue / String

## OUTPUTS

### JiraPS.Link

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Remove-JiraRemoteLink](../Remove-JiraRemoteLink/)
