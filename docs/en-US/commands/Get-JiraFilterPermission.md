---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraFilterPermission/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraFilterPermission/
---
# Get-JiraFilterPermission

## SYNOPSIS

Fetch the permissions of a specific Filter.

## SYNTAX

### ById (Default)

```powershell
Get-JiraFilterPermission [-Id] <uint[]> [-Credential <pscredential>] [<CommonParameters>]
```

### ByInputObject

```powershell
Get-JiraFilterPermission [-Filter] <Filter> [-Credential <pscredential>] [<CommonParameters>]
```

## DESCRIPTION

This allows the user to retrieve all the sharing permissions set for a Filter.

## EXAMPLES

### Example 1

```powershell
Get-JiraFilterPermission -Filter (Get-JiraFilter 12345)
#-------
Get-JiraFilterPermission -Id 12345
```

Two methods for retrieving the permissions set for Filter 12345.

### Example 2

```powershell
12345 | Get-JiraFilterPermission
#-------
Get-JiraFilter 12345 | Add-JiraFilterPermission
```

Two methods for retrieve the permissions set for Filter 12345 by using the pipeline.

The Id could be read from a file.

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
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Filter

Filter object from which to retrieve the permissions

```yaml
Type: JiraPS.Filter
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByInputObject
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Id

Id of the Filter from which to retrieve the permissions

```yaml
Type: UInt32[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ById
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
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### JiraPS.Filter


### System.UInt32[]

## OUTPUTS

### JiraPS.Filter

## NOTES

This function requires either the `-Credential` parameter to be passed or
a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraFilter](../Get-JiraFilter/)

[Add-JiraFilterPermission](../Add-JiraFilterPermission/)

[Remove-JiraFilterPermission](../Remove-JiraFilterPermission/)
