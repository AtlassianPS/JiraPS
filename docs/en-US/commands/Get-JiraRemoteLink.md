---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraRemoteLink/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraRemoteLink/
---
# Get-JiraRemoteLink

## SYNOPSIS

Returns a remote link from a Jira issue.

## SYNTAX

```powershell
Get-JiraRemoteLink -Issue <AtlassianPS.JiraPS.Issue> [-LinkId <Int32>] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

## DESCRIPTION

This function returns information on remote links from a  Jira issue.

## EXAMPLES

### Example 1

```powershell
Get-JiraRemoteLink -Issue TEST-001 -Credential $cred
```

Returns information about all remote links from the issue "TEST-001"

### Example 2

```powershell
Get-JiraRemoteLink -Issue TEST-001 -LinkId 100000 -Credential $cred
```

Returns information about a specific remote link from the issue "TEST-001"

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

### -Issue

The issue to search for link.

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

### -LinkId

Get a single link by it's ID.

```yaml
Type: Int32
DefaultValue: 0
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

### AtlassianPS.JiraPS.Issue / String

## OUTPUTS

### AtlassianPS.JiraPS.Link

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Remove-JiraRemoteLink](../Remove-JiraRemoteLink/)
