---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Add-JiraIssueLink/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Add-JiraIssueLink/
---
# Add-JiraIssueLink

## SYNOPSIS

Adds a link between two issues on Jira.

## SYNTAX

```powershell
Add-JiraIssueLink -IssueLink <AtlassianPS.JiraPS.IssueLinkCreateRequest[]> [-Comment <String>] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

## DESCRIPTION

Creates a new link of the specified type between two issues.

## EXAMPLES

### Example 1

```powershell
$_issueLink = [AtlassianPS.JiraPS.IssueLinkCreateRequest]@{
    inwardIssue = [AtlassianPS.JiraPS.LinkedIssueRef]@{ key = 'TEST-01' }
    outwardIssue = [AtlassianPS.JiraPS.LinkedIssueRef]@{ key = 'TEST-10' }
    type = [AtlassianPS.JiraPS.IssueLinkTypeRef]@{ name = 'Composition' }
}
Add-JiraIssueLink -IssueLink $_issueLink
```

Creates a link "is part of" between TEST-01 and TEST-10

### Example 2

```powershell
$_issueLink = New-JiraIssueLinkRequest -Type 'Blocks' -FromIssue 'TEST-01' -ToIssue 'TEST-10'
Add-JiraIssueLink -IssueLink $_issueLink
```

Creates a link using the helper cmdlet's simple `-Type` / `-FromIssue` / `-ToIssue` signature.

## PARAMETERS

### -Comment

Write a comment to the issue.

```yaml
Type: String
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

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
DefaultValue: ''
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

### -IssueLink

Issue Link to be created.
Accepts `AtlassianPS.JiraPS.IssueLinkCreateRequest` values and compatible payload objects that include `type`, `inwardIssue`, and `outwardIssue`.
The nested `type` object must include `name` or `id`.
The nested issue references must include `key` or `id`.
Both `inwardIssue` and `outwardIssue` are required.

```yaml
Type: AtlassianPS.JiraPS.IssueLinkCreateRequest[]
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

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
DefaultValue: ''
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

### AtlassianPS.JiraPS.IssueLinkCreateRequest

The issue-link create request payload that should be used.

## OUTPUTS

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[Get-JiraIssue](../Get-JiraIssue/)

[Get-JiraIssueLink](../Get-JiraIssueLink/)

[Get-JiraIssueLinkType](../Get-JiraIssueLinkType/)

[New-JiraIssueLinkRequest](../New-JiraIssueLinkRequest/)

[Remove-JiraIssueLink](../Remove-JiraIssueLink/)
