---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/New-JiraIssue/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/New-JiraIssue/
---
# New-JiraIssue

## SYNOPSIS

Creates a new issue in Jira.

## SYNTAX

### AssignToUser (Default)

```powershell
New-JiraIssue -Project <AtlassianPS.JiraPS.Project> -IssueType <AtlassianPS.JiraPS.IssueType> -Summary <String> [-Priority <AtlassianPS.JiraPS.Priority>] [-Description <String>] [-Reporter <AtlassianPS.JiraPS.User>] [-Assignee <AtlassianPS.JiraPS.User>] [-Label <String[]>] [-Parent <String>] [-FixVersion <AtlassianPS.JiraPS.Version[]>] [-Fields <PSObject>] [-Components <AtlassianPS.JiraPS.Component[]>] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [-ConnectionName <String>] [-Uri <Uri>] [-EmailAddress <String>] [-ApiToken <Object>] [-PersonalAccessToken <Object>] [-Anonymous] [<CommonParameters>]
```

### Unassign

```powershell
New-JiraIssue -Project <AtlassianPS.JiraPS.Project> -IssueType <AtlassianPS.JiraPS.IssueType> -Summary <String> [-Priority <AtlassianPS.JiraPS.Priority>] [-Description <String>] [-Reporter <AtlassianPS.JiraPS.User>] [-Unassign] [-Label <String[]>] [-Parent <String>] [-FixVersion <AtlassianPS.JiraPS.Version[]>] [-Fields <PSObject>] [-Components <AtlassianPS.JiraPS.Component[]>] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [-ConnectionName <String>] [-Uri <Uri>] [-EmailAddress <String>] [-ApiToken <Object>] [-PersonalAccessToken <Object>] [-Anonymous] [<CommonParameters>]
```

## DESCRIPTION

This function creates a new issue in Jira.

Creating an issue requires a lot of data, and the exact data may be different from one instance of Jira to the next.

To identify what data is available for a given issue type and project, use the `Get-JiraIssueCreateMetadata` function provided in this module.
Jira's create metadata is informative, but the Jira create endpoint remains the source of truth for whether a field is actually required for API callers.
`New-JiraIssue` therefore sends the request to Jira and surfaces any server-side field validation errors returned by the API, instead of pre-emptively rejecting the call based only on create metadata.

Some Jira instances may require additional custom fields specific to that instance of Jira.
In addition to the parameterized fields provided in this function, the Fields parameter accepts a hashtable of field names/IDs and values.
This allows users to provide custom field data when creating an issue.
Read more about it in [about_JiraPS_CustomFields](../../about/custom-fields.html)

On **Jira Cloud**, the `-Description` text is interpreted as Markdown and converted to Atlassian Document Format (ADF) before being sent, so familiar Markdown syntax (headings, bold/italic, lists, fenced code blocks, links, Markdown tables) renders as rich text on the new issue.
On **Jira Server / Data Center**, the description is sent verbatim and the legacy wiki-markup syntax continues to apply.
See [`ConvertTo-AtlassianDocumentFormat`](../ConvertTo-AtlassianDocumentFormat/) for the supported Markdown subset.

## EXAMPLES

### Example 1

```powershell
New-JiraIssue -Project 'TEST' -Type 'Bug' -Summary 'Test issue'
```

Creates a new issue in the TEST project.

This is the simplest way possible to use the command, given the project only requires these fields as mandatory.

### Example 2

```powershell
Get-JiraIssueCreateMetadata -Project TEST -IssueType Bug | Where-Object {$_.Required -eq $true}
New-JiraIssue -Project TEST -IssueType Bug -Priority 1 -Summary 'Test issue from PowerShell' -Description 'This is a test issue created from the JiraPS module in PowerShell.' -Fields @{'Custom Field Name 1'=@{'foo' = 'bar'};'customfield_10001'=@('baz');}
```

This example uses `Get-JiraIssueCreateMetadata` to identify fields required to create an issue in Jira.
It then creates an issue with the Fields parameter providing a field name and a field ID.

### Example 3

```powershell
$parameters = @{
    Project = 'TEST'
    IssueType = 'Bug'
    Priority = 1
    Summary = 'Test issue from PowerShell'
    Description = 'This is a test issue created from the JiraPS module in PowerShell.'
    Fields = @{
        'Custom Field Name 1' = @{'foo' = 'bar'}
        customfield_10001 = @('baz')
    }
}
New-JiraIssue @parameters
```

This illustrates how to use splatting for the example above.

Read more about splatting: about_Splatting

### Example 4

```powershell
'project,summary,assignee,IssueType,Priority,Description' > './data.csv'
'CS,Some Title 1,admin,Minor,1,Some Description 1' >> './data.csv'
'CS,Some Title 2,admin,Minor,1,Some Description 2' >> './data.csv'
import-csv './data.csv' | New-JiraIssue
```

This example illuetrates how to prepare multiple new stories and pipe them to be created all at once.

### Example 5

```powershell
New-JiraIssue -Project TEST -IssueType Bug -Summary 'Triage me' -Assignee 'alice'
New-JiraIssue -Project TEST -IssueType Bug -Summary 'Backlog item' -Unassign
New-JiraIssue -Project TEST -IssueType Bug -Summary 'Default flow'
```

The first call assigns the new issue to `alice`.
The second call creates the issue with no assignee (the project's default is bypassed).
The third call omits both parameters; Jira applies the project's default assignee, if any.

## PARAMETERS

### -Assignee

User to assign the new issue to.
Accepts a username (Jira Server / Data Center), an `accountId` (Jira Cloud), or a `AtlassianPS.JiraPS.User` object.

If omitted, Jira will apply the project's default assignee — there is no separate `-UseDefaultAssignee` switch on this cmdlet because the create endpoint already does the right thing when the field is missing.

To create an issue with no assignee, use `-Unassign` instead.

```yaml
Type: AtlassianPS.JiraPS.User
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AssignToUser
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Components

Component objects, IDs or names to add to the issue.
An object with an ID sends that ID; a name-only object sends its name for Jira to resolve in the project.

```yaml
Type: AtlassianPS.JiraPS.Component[]
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
DefaultValue: None
SupportsWildcards: false
Aliases:
- cf
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

### -Credential

Username/password or compatible Cloud email/token as PSCredential. Explicit input temporarily overrides the selected identity without inheriting cookies or changing the stored connection. An empty credential fails; omitted input uses the selected connection.

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

### -Description

Long description of the issue.

```yaml
Type: String
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Fields

Any additional fields.

When you provide field names in `-Fields`, JiraPS first resolves them against create metadata returned by `Get-JiraIssueCreateMetadata` for the target project and issue type.
If a provided key is not present in that scoped metadata, JiraPS falls back to the global `Get-JiraField` catalogue.
Using scoped metadata first avoids ambiguous name matching when duplicate custom-field display names exist across projects.

See: about_JiraPS_CustomFields

On **Jira Cloud**, string values supplied for rich-text fields (`description`, `environment`, and custom textarea fields with schema type `doc`) are interpreted as Markdown and converted to Atlassian Document Format (ADF) before being sent, matching the behaviour of the explicit `-Description` parameter.
Plain string fields, numeric fields, dates, etc. are forwarded as-is.
Hashtable / object values are also forwarded as-is — pass a pre-built ADF document if you need full control.
On **Jira Server / Data Center** the value is always forwarded verbatim.

```yaml
Type: PSObject
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -FixVersion

Version objects, IDs or names to assign as fix versions.
An object with an ID sends that ID; a name-only object sends its name for Jira to resolve in the project.
Numeric strings are interpreted as IDs; to select a numeric version name, use an explicit name object such as `[AtlassianPS.JiraPS.Version]@{ Name = '2026' }`.

```yaml
Type: AtlassianPS.JiraPS.Version[]
DefaultValue: None
SupportsWildcards: false
Aliases:
- FixVersions
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IssueType

Issue type object, ID or name available in the selected project.
An object with an ID selects that exact issue type.

```yaml
Type: AtlassianPS.JiraPS.IssueType
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Label

List of labels which will be added to the issue.

```yaml
Type: String[]
DefaultValue: None
SupportsWildcards: false
Aliases:
- Labels
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Parent

Parent issue - in case of issues of type "Sub-Tasks".

```yaml
Type: String
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Priority

Priority object, ID or unambiguous priority name.
An object with an ID sends that ID without an additional lookup.
A name must match exactly one result from `Get-JiraPriority`; the cmdlet sends the matching ID.
A missing or ambiguous name terminates the command before an issue is created.

```yaml
Type: AtlassianPS.JiraPS.Priority
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Project

Project object, key or ID in which to create the issue.

```yaml
Type: AtlassianPS.JiraPS.Project
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Reporter

User that shall be registered as the reporter.

If omitted, Jira will apply the default reporter (typically the currently authenticated user).
Empty, `$null`, and whitespace-only values are rejected at parameter binding.

```yaml
Type: AtlassianPS.JiraPS.User
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Summary

Summary of the issue.

```yaml
Type: String
DefaultValue: None
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Unassign

Create the issue with no assignee, even if the project defines a default assignee.
Mutually exclusive with `-Assignee`.

```yaml
Type: SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Unassign
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
DefaultValue: None
SupportsWildcards: false
Aliases:
- wi
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

Live shared connection for this operation. Session is a compatibility alias. The object must be active in this runspace and belong to Jira.

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

### -ConnectionName

Case-insensitive name of an active Jira connection. Server and ServerName are compatibility aliases. This parameter is mutually exclusive with Connection and a standalone endpoint.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Server, ServerName

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Uri

Standalone Jira product endpoint for this logical operation. Cannot be combined with Connection or ConnectionName. Supply one explicit authentication mode; use Anonymous for anonymous access. Normal HTTPS commercial Atlassian site URLs resolve cloudId and the API gateway automatically for ApiToken authentication.

```yaml
Type: Uri
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EmailAddress

Cloud authentication email for ApiToken. Email is an alias. An override must supply both its own email and token.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Email

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApiToken

Cloud API token as a nonempty string or SecureString. Supply the authentication email in the same call. The module normalizes the secret and resolves a normal Cloud site URL automatically.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PersonalAccessToken

Data Center PAT as a nonempty string or SecureString. PAT and BearerToken are aliases. No dummy username is required.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: PAT, BearerToken

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Anonymous

Explicit anonymous authentication when the Jira endpoint permits it. Never borrows the default connection identity.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: None

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

### AtlassianPS.JiraPS.Issue

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent Jira session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to Jira.

## RELATED LINKS

[about_JiraPS_CreatingIssues](../../about/creating-issues.html)

[about_JiraPS_CustomFields](../../about/custom-fields.html)

[Get-JiraIssueCreateMetadata](../Get-JiraIssueCreateMetadata/)

[Get-JiraComponent](../Get-JiraComponent/)

[Get-JiraField](../Get-JiraField/)

[Get-JiraPriority](../Get-JiraPriority/)

[Get-JiraProject](../Get-JiraProject/)

[Get-JiraVersion](../Get-JiraVersion/)
