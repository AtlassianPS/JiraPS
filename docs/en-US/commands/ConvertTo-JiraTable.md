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

Converts an object into a Jira **wiki-markup** table string (Server / Data Center native format).

## SYNTAX

```powershell
ConvertTo-JiraTable [-InputObject] <psobject[]> [[-Property] <Object[]>] [<CommonParameters>]
```

## DESCRIPTION

Converts one or more PowerShell objects into a string formatted as a Jira **wiki-markup** table (`||header||header|| ... |cell|cell|`).
The result is a `[String]` suitable for passing to commands such as `Add-JiraIssueComment` or `Add-JiraIssueWorklog`, or for assignment to text fields on Jira Server / Data Center.

Despite producing tabular output, this cmdlet is intentionally a `ConvertTo-*` rather than a `Format-*`: it returns a `[String]`, not the host-only display objects emitted by built-in `Format-*` cmdlets such as `Format-Table`.

> **Jira Cloud caveat.**
> The output is wiki markup, the native format on Server / Data Center.
> Jira **Cloud** (REST v3) expects [Atlassian Document Format (ADF)](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/) and renders `||header||` syntax as literal text rather than as a table.
> Wrapping these payloads in ADF on Cloud is tracked in [#602](https://github.com/AtlassianPS/JiraPS/issues/602).

Deprecated alias: `Format-Jira` (will be removed in a future major version; update scripts to call `ConvertTo-JiraTable` directly).

## EXAMPLES

### EXAMPLE 1

```powershell
$summary = Get-JiraIssue -Query 'project = TEST AND status != Done AND assignee = currentUser()' |
    ConvertTo-JiraTable -Property Key, Summary, Status, Priority
Add-JiraIssueComment -Issue TEST-100 -Comment "My open issues:`n$summary"
```

This example tabulates the caller's open issues in project TEST and posts the resulting wiki-markup table as a comment on the parent ticket TEST-100.
This is the canonical use case: assemble a small report from `Get-Jira*` output and embed it in another issue.
The JQL used here works on any Jira deployment (Core, Service Management, Software) — replace it with whatever filter your reporting workflow needs.

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

This is a destructive transform: it walks the input pipeline and emits a single `[String]`, so any per-object data not selected via `-Property` is dropped.
Remember to "filter left, format right!"

**Output format.**
The output is Jira **wiki markup**, the native format for text fields on Jira Server / Data Center and for the legacy v2 REST API endpoints used by JiraPS write commands such as `Add-JiraIssueComment` and `Add-JiraIssueWorklog`.
On Jira Cloud (REST v3 / ADF) the table syntax renders as literal text; ADF wrapping for the write-side cmdlets is tracked in [#602](https://github.com/AtlassianPS/JiraPS/issues/602).

Alias: `Format-Jira` (deprecated)

## RELATED LINKS

[Add-JiraIssueComment](Add-JiraIssueComment.md)

[Add-JiraIssueWorklog](Add-JiraIssueWorklog.md)

[ConvertTo-AtlassianDocumentFormat](ConvertTo-AtlassianDocumentFormat.md)
