---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraField/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraField/
---
# Get-JiraField

## SYNOPSIS

This function returns information about JIRA fields

## SYNTAX

### _All (Default)

```powershell
Get-JiraField [-Force] [-Credential <PSCredential>] [<CommonParameters>]
```

### _Search

```powershell
Get-JiraField [-Field] <String[]> [-Force] [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

This function provides information about JIRA fields, or about one field in particular.
This is a good way to identify a field's ID by its name, or vice versa.

Typically, this information is only needed when identifying what fields are necessary to create or edit issues.
See `Get-JiraIssueCreateMetadata` for more details.

Results are cached for 60 minutes to reduce API calls. Use the `-Force` parameter
to bypass the cache and fetch fresh data from the server.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraField
```

This example returns information about all JIRA fields visible to the current user.

### EXAMPLE 2

```powershell
Get-JiraField "Key"
```

This example returns information about the Key field.

### EXAMPLE 3

```powershell
Get-JiraField -Force
```

This example bypasses the cache and fetches fresh field data from the server.

## PARAMETERS

### -Field

The Field name or ID to search.

```yaml
Type: String[]
Parameter Sets: _Search
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Force

Bypass the cache and fetch fresh data from the server.

By default, field data is cached for 60 minutes to reduce API calls.
Use this parameter when you need the most up-to-date field information,
for example after making configuration changes in Jira.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

Credentials to use to connect to JIRA.  
If not specified, this function will use anonymous access.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [JiraPS.Field]

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

Results are cached for 60 minutes per server. Use `-Force` to bypass the cache,
or use `Clear-JiraCache -Type Fields` to clear all cached field data.

Remaining operations for `field` have not yet been implemented in the module.

## RELATED LINKS

[Get-JiraIssueCreateMetadata](../Get-JiraIssueCreateMetadata/)

[Clear-JiraCache](../Clear-JiraCache/)
