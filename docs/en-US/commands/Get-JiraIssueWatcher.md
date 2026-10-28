---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueWatcher/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueWatcher/
---
# Get-JiraIssueWatcher

## SYNOPSIS

Returns watchers on an issue in Jira.

## SYNTAX

```powershell
Get-JiraIssueWatcher [-Issue] <AtlassianPS.JiraPS.Issue> [[-Credential] <pscredential>] [[-Connection] <AtlassianPS.Connection>] [<CommonParameters>]
```

## DESCRIPTION

This function obtains watchers from existing issues in Jira.

## EXAMPLES

### Example 1

```powershell
Get-JiraIssueWatcher -Key TEST-001
```

This example returns all watchers posted to issue TEST-001.

### Example 2

```powershell
Get-JiraIssue TEST-002 | Get-JiraIssueWatcher
```

This example illustrates use of the pipeline to return all watchers on issue TEST-002.

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

Jira issue to check for watchers.

Can be an `AtlassianPS.JiraPS.Issue` object, issue key, or internal issue ID.

```yaml
Type: AtlassianPS.JiraPS.Issue
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Key
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable.
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.Issue / String

## OUTPUTS

### AtlassianPS.JiraPS.User

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Add-JiraIssueWatcher](../Add-JiraIssueWatcher/)

[Remove-JiraIssueWatcher](../Remove-JiraIssueWatcher/)
