---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/ConvertFrom-AtlassianDocumentFormat/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/ConvertFrom-AtlassianDocumentFormat/
---
# ConvertFrom-AtlassianDocumentFormat

## SYNOPSIS

Converts an Atlassian Document Format (ADF) object to Markdown.

## SYNTAX

```powershell
ConvertFrom-AtlassianDocumentFormat [[-InputObject] <Object>] [<CommonParameters>]
```

## DESCRIPTION

Jira Cloud API v3 returns description, comments, and many custom fields as ADF JSON objects.
This function converts ADF to Markdown, preserving headings, bold, italic, strikethrough, inline code, links, bullet/ordered/task lists, tables, code blocks, blockquotes, mentions, emoji, and dates.

Plain strings (Data Center / API v2) are returned unchanged.

## EXAMPLES

### EXAMPLE 1

```powershell
$raw = Invoke-JiraMethod -Uri "$server/rest/api/3/issue/TEST-1" -Method Get
$markdown = ConvertFrom-AtlassianDocumentFormat -InputObject $raw.fields.description
```

Converts the ADF description returned by the Jira Cloud v3 API into readable Markdown.

### EXAMPLE 2

```powershell
$raw.fields.description | ConvertFrom-AtlassianDocumentFormat
```

The same conversion using pipeline input.

### EXAMPLE 3

```powershell
$comments = Invoke-JiraMethod -Uri "$server/rest/api/3/issue/TEST-1/comment" -Method Get
$comments.comments | ForEach-Object {
    ConvertFrom-AtlassianDocumentFormat -InputObject $_.body
}
```

Converts each ADF comment body to Markdown.

## PARAMETERS

### -InputObject

The ADF object (PSCustomObject with type = "doc") or a plain string.
When a plain string is provided it is returned unchanged, making the function safe
to use regardless of whether the server returns ADF or wiki markup.

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: false
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

### System.Object

An ADF document object (PSCustomObject or hashtable) or a plain string.

## OUTPUTS

### System.String

A Markdown representation of the ADF input, or the original string if the input was not ADF.

## NOTES

This function is public because JiraPS's read commands (`Get-JiraIssue`, `Get-JiraIssueComment`)
only convert ADF automatically when they use API v3 internally.
Users who call `Invoke-JiraMethod`
directly against Jira Cloud v3 endpoints receive raw ADF objects that need manual conversion.
Making this function public lets users convert those responses to Markdown without reimplementing
the logic.

It is also useful for inspecting the raw ADF structure returned by the API alongside the
converted Markdown output.

Alias: `ConvertFrom-ADF`

## RELATED LINKS

[ConvertTo-AtlassianDocumentFormat](ConvertTo-AtlassianDocumentFormat.md)

[Invoke-JiraMethod](Invoke-JiraMethod.md)

[Atlassian Document Format](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/)
