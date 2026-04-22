---
document type: cmdlet
external help file: JiraPS-help.xml
HelpUri: https://atlassianps.org/docs/JiraPS/commands/Get-JiraField/
Locale: en-DE
Module Name: JiraPS
ms.date: 04.22.2026
PlatyPS schema version: 2024-05-01
title: Get-JiraField
---

# Get-JiraField

## SYNOPSIS

This function returns information about JIRA fields

## SYNTAX

### _All (Default)

```
Get-JiraField [-Force] [-Credential <pscredential>] [<CommonParameters>]
```

### _Search

```
Get-JiraField [-Field] <string[]> [-Force] [-Credential <pscredential>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function provides information about JIRA fields, or about one field in particular.
This is a good way to identify a field's ID by its name, or vice versa.

Typically, this information is only needed when identifying what fields are necessary to create or edit issues.
See `Get-JiraIssueCreateMetadata` for more details.

Results are cached for 60 minutes to reduce API calls.
Use the `-Force` parameter to bypass the cache and fetch fresh data from the server.

## EXAMPLES

### EXAMPLE 1

Get-JiraField


This example returns information about all JIRA fields visible to the current user.

### EXAMPLE 2

Get-JiraField "Key"


This example returns information about the Key field.

### EXAMPLE 3

Get-JiraField -Force


This example bypasses the cache and fetches fresh field data from the server.

## PARAMETERS

### -Credential

Credentials to use to connect to JIRA.
If not specified, this function will use anonymous access.

```yaml
Type: System.Management.Automation.PSCredential
DefaultValue: ''
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

### -Field

The Field name or ID to search.

```yaml
Type: System.String[]
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

### -Force

Bypass the cache and fetch fresh data from the server.

By default, field data is cached for 60 minutes to reduce API calls.
Use this parameter when you need the most up-to-date field information,
for example after making configuration changes in Jira.

```yaml
Type: System.Management.Automation.SwitchParameter
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String[]

{{ Fill in the Description }}

## OUTPUTS

### JiraPS.Field

{{ Fill in the Description }}

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

Results are cached for 60 minutes per server.
Use `-Force` to bypass the cache,
or use `Clear-JiraCache -Type Fields` to clear all cached field data.

Remaining operations for `field` have not yet been implemented in the module.


## RELATED LINKS

- [Online Version](https://atlassianps.org/docs/JiraPS/commands/Get-JiraField/)
- [Get-JiraIssueCreateMetadata](../Get-JiraIssueCreateMetadata/)
- [Clear-JiraCache](../Clear-JiraCache/)
