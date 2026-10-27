---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueCreateMetadata/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueCreateMetadata/
---
# Get-JiraIssueCreateMetadata

## SYNOPSIS

Returns metadata required to create an issue in Jira.

## SYNTAX

```powershell
Get-JiraIssueCreateMetadata -Project <AtlassianPS.JiraPS.Project> -IssueType <AtlassianPS.JiraPS.IssueType> [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>] [<CommonParameters>]
```

## DESCRIPTION

This function returns metadata required to create an issue in Jira - the fields that can be defined in the process of creating an issue.
This can be used to identify custom fields in order to pass them to `New-JiraIssue`.

This function is particularly useful when your Jira instance includes custom fields that are marked as mandatory.

The cmdlet returns typed `AtlassianPS.JiraPS.CreateMetaField` objects and walks every offset page on Jira Cloud and Data Center.
The full set of fields is returned by default even when the issue type has more fields than a single page holds.
Use the `-First` / `-Skip` / `-IncludeTotalCount` common pagination parameters to limit or offset the results.

## EXAMPLES

### Example 1

```powershell
Get-JiraIssueCreateMetadata -Project 'TEST' -IssueType 'Bug'
```

This example returns all fields available when creating an issue of type Bug under project TEST, walking pagination as needed.

### Example 2

```powershell
Get-JiraIssueCreateMetadata -Project 'TEST' -IssueType 'Bug' |
    Where-Object { $_.Required }
```

This example returns fields available when creating an issue of type Bug in project TEST.

It then uses `Where-Object` to filter only the fields that are required.

### Example 3

```powershell
Get-JiraIssueCreateMetadata -Project 'TEST' -IssueType 'Bug' -First 10
```

This example returns only the first 10 fields, regardless of how many pages the Jira API would normally return.

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

### -First

Indicates how many items to return.

```yaml
Type: UInt64
DefaultValue: 18446744073709551615
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

### -IncludeTotalCount

Causes an extra output of the total count at the beginning.

Note this is actually a uInt64, but with a custom string representation.

```yaml
Type: SwitchParameter
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

### -IssueType

Issue type ID or name.

```yaml
Type: AtlassianPS.JiraPS.IssueType
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Project

Project ID or key of the reference issue.

```yaml
Type: AtlassianPS.JiraPS.Project
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Skip

Controls how many things will be skipped before starting output.

Defaults to 0.

```yaml
Type: UInt64
DefaultValue: 0
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

## OUTPUTS

### AtlassianPS.JiraPS.CreateMetaField

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[about_JiraPS_CreatingIssues](../../about/creating-issues.html)

[Get-JiraField](../Get-JiraField/)

[New-JiraIssue](../New-JiraIssue/)
