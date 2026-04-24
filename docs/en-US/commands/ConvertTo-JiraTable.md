---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/ConvertTo-JiraTable/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/ConvertTo-JiraTable/
---
# ConvertTo-JiraTable

## SYNOPSIS

Converts an object into a Jira wiki-markup table string.

## SYNTAX

```powershell
ConvertTo-JiraTable [-InputObject] <psobject[]> [[-Property] <Object[]>] [<CommonParameters>]
```

## DESCRIPTION

Converts one or more PowerShell objects into a string formatted as a Jira wiki-markup table.
The result is a `[String]` suitable for passing to commands such as `Add-JiraIssueComment` or `Add-JiraIssueWorklog`, or for assignment to text fields on Jira Data Center.

Despite producing tabular output, this cmdlet is intentionally a `ConvertTo-*` rather than a `Format-*`: it returns a `[String]`, not the host-only display objects emitted by built-in `Format-*` cmdlets such as `Format-Table`.

Deprecated alias: `Format-Jira` (will be removed in a future major version; update scripts to call `ConvertTo-JiraTable` directly).

## EXAMPLES

### EXAMPLE 1

```powershell
$summary = Get-JiraIssue -Query 'project = TEST AND sprint in openSprints()' |
    ConvertTo-JiraTable -Property Key, Summary, Status, Assignee
Add-JiraIssueComment -Issue TEST-100 -Comment "Sprint status:`n$summary"
```

This example tabulates the in-flight issues of the current sprint of project TEST and posts the resulting wiki-markup table as a comment on the parent ticket TEST-100.
This is the canonical use case: assemble a small report from `Get-Jira*` output and embed it in another issue.

### EXAMPLE 2

```powershell
Get-Process chrome | ConvertTo-JiraTable Name, Id, VM
```

`ConvertTo-JiraTable` accepts any `PSObject` pipeline, not just Jira objects.
This example obtains all Google Chrome processes and creates a Jira wiki-markup table containing only the Name, Id, and VM properties of each one.

## PARAMETERS

### -InputObject

Object to format.

```yaml
Type: PSObject[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: true
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Property

List of properties to display.
If omitted, only the default properties will be shown.

To display all properties, use `-Property *`.

```yaml
Type: Object[]
DefaultValue: ''
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

## OUTPUTS

### System.String

## NOTES

Like the native `Format-*` cmdlets, this is a destructive operation for data in the pipeline.
Remember to "filter left, format right!"

The output is Jira **wiki markup**, which is the native format for text fields on Jira Data Center and for the legacy v2 API endpoints used by JiraPS write commands such as `Add-JiraIssueComment` and `Add-JiraIssueWorklog`.
For Jira Cloud v3 endpoints (which require Atlassian Document Format), wrap the result with `ConvertTo-AtlassianDocumentFormat` before submitting it.

Alias: `Format-Jira` (deprecated)

## RELATED LINKS

[Add-JiraIssueComment](Add-JiraIssueComment.md)

[Add-JiraIssueWorklog](Add-JiraIssueWorklog.md)

[ConvertTo-AtlassianDocumentFormat](ConvertTo-AtlassianDocumentFormat.md)
