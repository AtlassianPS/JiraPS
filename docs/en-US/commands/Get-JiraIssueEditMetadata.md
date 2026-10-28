---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueEditMetadata/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueEditMetadata/
---
# Get-JiraIssueEditMetadata

## SYNOPSIS

Returns metadata required to change an issue in JIRA

## SYNTAX

```powershell
Get-JiraIssueEditMetadata [-Issue] <string> [[-Credential] <pscredential>] [[-Connection] <AtlassianPS.Connection>] [<CommonParameters>]
```

## DESCRIPTION

This function returns metadata required to update an issue in JIRA - the fields that can be defined in the process of updating an issue.
This can be used to identify custom fields in order to pass them to `Set-JiraIssue`.

This function is particularly useful when your JIRA instance includes custom fields that are marked as mandatory.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraIssueEditMetadata -Issue "TEST-001"
```

This example returns the fields available when updating the issue "TEST-001".

### EXAMPLE 2

```powershell
Get-JiraIssueEditMetadata -Issue "TEST-001" | ? {$_.Required -eq $true}
```

This example returns fields available when updating the issue "TEST-001".
It then uses `Where-Object` (aliased by the question mark) to filter only the fields that are required.

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
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Issue

Issue id or key of the reference issue.

```yaml
Type: String
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
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### JiraPS.Field

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[about_JiraPS_UpdatingIssues](../../about/updating-issues.html)

[Get-JiraField](../Get-JiraField/)

[Set-JiraIssue](../Set-JiraIssue/)
