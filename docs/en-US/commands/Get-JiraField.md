---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraField/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraField/
---
# Get-JiraField

## SYNOPSIS

This function returns information about Jira fields.

## SYNTAX

### _All (Default)

```powershell
Get-JiraField [-Force] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

### _Search

```powershell
Get-JiraField -Field <AtlassianPS.JiraPS.Field[]> [-Force] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

## DESCRIPTION

This function provides information about Jira fields, or about one field in particular.
This is a good way to identify a field's ID by its name, or vice versa.

Typically, this information is only needed when identifying what fields are necessary to create or edit issues.
See `Get-JiraIssueCreateMetadata` for more details.

Results are cached for 60 minutes to reduce API calls.
Use the `-Force` parameter to bypass the cache and fetch fresh data from the server.

## EXAMPLES

### Example 1

```powershell
Get-JiraField
```

This example returns information about all Jira fields visible to the current user.

### Example 2

```powershell
Get-JiraField 'Key'
```

This example returns information about the Key field.

### Example 3

```powershell
Get-JiraField -Force
```

This example bypasses the cache and fetches fresh field data from the server.

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

### -Field

Field objects, field IDs or wildcard field names.
An exact ID takes precedence over a display-name match.

```yaml
Type: AtlassianPS.JiraPS.Field[]
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
Use this parameter when you need the most up-to-date field information, for example after making configuration changes in Jira.

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

### AtlassianPS.JiraPS.Field

Pipe a field object to retrieve its current details.

### System.String

Pipe a field ID or name pattern.

## OUTPUTS

### AtlassianPS.JiraPS.Field

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

Results are cached for 60 minutes per server.
Use `-Force` to bypass the cache, or use `Clear-JiraCache -Type Fields` to clear all cached field data.

Remaining operations for `field` have not yet been implemented in the module.

## RELATED LINKS

[Get-JiraIssueCreateMetadata](../Get-JiraIssueCreateMetadata/)

[Clear-JiraCache](../Clear-JiraCache/)
