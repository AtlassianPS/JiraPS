---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraGroup/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraGroup/
---
# Get-JiraGroup

## SYNOPSIS

Returns a group from Jira

## SYNTAX

```powershell
Get-JiraGroup [-GroupName] <string[]> [[-Credential] <pscredential>] [<CommonParameters>]
```

## DESCRIPTION

This function attempts to return canonical information for a specified group from JIRA.

On Jira Cloud, the cmdlet uses the modern group lookup endpoint and returns the group's `Id` when Jira provides it.
On Jira Data Center, the cmdlet uses the paged group-members endpoint because Jira 11 removed the legacy `GET /group?groupname=` lookup path.
That keeps canonical group resolution working on current Data Center releases, although the Data Center payload is adapted from the group-members response rather than a dedicated canonical group document.
On Cloud, the cmdlet requires exactly one exact name match from the bulk endpoint before it returns a group object.
If Jira does not return a usable canonical group payload for a requested name, the cmdlet writes a non-terminating `GroupNotFound` error so other requested groups can still be processed unless `-ErrorAction Stop` is used.

Prefer passing the group name directly to `Get-JiraGroupMember`, `Add-JiraGroupMember`, `Remove-JiraGroupMember`, or `Remove-JiraGroup` unless you specifically need the canonical group payload.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraGroup -GroupName testGroup
```

Returns information about the group "testGroup"

### EXAMPLE 2

```powershell
Get-JiraGroup -GroupName testGroup |
  Select-Object Name, Id
```

This example returns the canonical properties Jira exposes for "testGroup".

### EXAMPLE 3

```powershell
Get-JiraGroup -GroupName existing-group, missing-group -ErrorVariable groupErrors
```

This example returns the groups Jira can resolve and stores any `GroupNotFound` lookup errors in `$groupErrors`.

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
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -GroupName

Name of the group to search for.

```yaml
Type: String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Name
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### JiraPS.Group

Returned group objects may include an `Id` property when Jira provides one.
Jira Data Center responses do not expose a canonical group `Id`, so the property may be empty on that track.
Missing groups are reported as non-terminating `GroupNotFound` errors rather than as output objects.

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

`Get-JiraGroup` uses different REST paths on Cloud and Data Center because the canonical group lookup surface diverged between the two products.
On Jira Cloud, only an exact canonical match is accepted.
On Jira Data Center, the cmdlet derives canonical group information from `/group/member` because the old `/group?groupname=` path is no longer available on current releases.
If you only need to work with a known group name, prefer the cmdlets that accept `-Group` or `-GroupName` directly.

## RELATED LINKS

[Get-JiraGroupMember](../Get-JiraGroupMember/)

[Get-JiraUser](../Get-JiraUser/)

[New-JiraGroup](../New-JiraGroup/)

[Remove-JiraGroup](../Remove-JiraGroup/)
