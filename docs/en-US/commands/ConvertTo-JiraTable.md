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

> **Important — Jira Cloud compatibility.**
> Wiki markup is the native rendering format for Jira **Server / Data Center** and for the **legacy v2 REST API**.
> Jira **Cloud REST v3** endpoints expect [Atlassian Document Format (ADF)](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/) and will render `||header||` syntax as literal text, not as a table.
> The output of this cmdlet is therefore best suited to Data Center / Server, or to Cloud workflows that explicitly target the legacy v2 REST endpoints.
> When invoked while the active session is connected to a Cloud deployment, the cmdlet emits a `Write-Warning` that can be silenced with `-WarningAction SilentlyContinue` (see [NOTES](#notes)).
> There is currently no clean wiki-markup → ADF round-trip helper in JiraPS — `ConvertTo-AtlassianDocumentFormat` consumes Markdown table syntax (`|cell|cell|`), not Jira wiki-markup tables (`||header||header||`).

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

**Output format.**
The output is Jira **wiki markup**, the native format for text fields on Jira Server / Data Center and for the legacy v2 REST API endpoints used by JiraPS write commands such as `Add-JiraIssueComment` and `Add-JiraIssueWorklog`.

**Jira Cloud caveat.**
Jira Cloud REST v3 endpoints expect Atlassian Document Format (ADF) and render `||header||` / `|cell|` strings as literal text rather than as a table.
When the active JiraPS session is connected to a Cloud deployment, the cmdlet emits a one-shot `Write-Warning` per invocation describing this mismatch.
The check uses `Test-JiraCloudServer`, which in turn calls the cached `Get-JiraServerInformation` (5-minute TTL), so it does not add a per-call HTTP round-trip.
If no session is configured (no `Set-JiraConfigServer` / `New-JiraSession`), the check is silently skipped — `ConvertTo-JiraTable` is also valid as a pure offline string formatter.
Suppress the warning with `-WarningAction SilentlyContinue` when you knowingly target Cloud's legacy v2 endpoints.

Alias: `Format-Jira` (deprecated)

## RELATED LINKS

[Add-JiraIssueComment](Add-JiraIssueComment.md)

[Add-JiraIssueWorklog](Add-JiraIssueWorklog.md)

[ConvertTo-AtlassianDocumentFormat](ConvertTo-AtlassianDocumentFormat.md)
