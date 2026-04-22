---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/ConvertTo-AtlassianDocumentFormat/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/ConvertTo-AtlassianDocumentFormat/
---
# ConvertTo-AtlassianDocumentFormat

## SYNOPSIS

Converts Markdown to Atlassian Document Format (ADF).

## SYNTAX

```powershell
ConvertTo-AtlassianDocumentFormat [-Markdown] <string> [<CommonParameters>]
```

## DESCRIPTION

Jira Cloud API v3 requires description, comments, and similar text fields to be submitted as ADF JSON objects.
This function parses a Markdown string and produces the corresponding ADF structure.

Supported Markdown constructs:

- **Block**: headings (# to ######), code fences, blockquotes (>), tables, bullet lists (\* item), ordered lists (1.
item), task lists (\* [ ] / \* [x]), images (!\[alt\](url)) - **Inline**: \*\*bold\*\*, \_italic\_, \~\~strike\~\~, \`code\`, \[text\](url)

## EXAMPLES

### EXAMPLE 1

```powershell
$adf = ConvertTo-AtlassianDocumentFormat -Markdown "**Hello** world"
$body = @{ body = $adf } | ConvertTo-Json -Depth 20
Invoke-JiraMethod -Uri "$server/rest/api/3/issue/TEST-1/comment" -Method Post -Body $body
```

Converts a Markdown string to ADF and posts it as a comment via the Jira Cloud v3 API.

### EXAMPLE 2

```powershell
$description = @"
# Release Notes
```

* Bug fix for login
* New dashboard widget
"@ | ConvertTo-AtlassianDocumentFormat

$body = @{ fields = @{ description = $description } } | ConvertTo-Json -Depth 20
Invoke-JiraMethod -Uri "$server/rest/api/3/issue/TEST-1" -Method Put -Body $body

Updates an issue description on Jira Cloud using Markdown converted to ADF.

### EXAMPLE 3

```powershell
$adf = ConvertTo-AtlassianDocumentFormat -Markdown "**Hello** world"
$adf | ConvertTo-Json -Depth 20
```

Inspects the ADF structure generated from a simple Markdown string.

## PARAMETERS

### -Markdown

The Markdown string to convert to ADF.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
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

### System.String

A Markdown-formatted string.

## OUTPUTS

### System.Collections.Hashtable

An ADF document as a hashtable with `version`, `type`, and `content` keys,
ready to be serialized to JSON with `ConvertTo-Json -Depth 20`.

## NOTES

The output must be serialized with sufficient depth (`-Depth 20` or higher)
to preserve the nested ADF structure.

This function is public because JiraPS's write commands (`New-JiraIssue`, `Set-JiraIssue`,
`Add-JiraIssueComment`) currently use API v2, which accepts plain text or wiki markup.
Users who need to write to Jira Cloud v3 endpoints via `Invoke-JiraMethod` must supply ADF.
Making this function public lets users convert Markdown to ADF for those calls without
reimplementing the logic.

Alias: `ConvertTo-ADF`

## RELATED LINKS

[ConvertFrom-AtlassianDocumentFormat](ConvertFrom-AtlassianDocumentFormat.md)

[Invoke-JiraMethod](Invoke-JiraMethod.md)

[Atlassian Document Format](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/)
