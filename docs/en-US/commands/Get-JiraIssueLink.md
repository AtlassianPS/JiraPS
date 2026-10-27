---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueLink/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueLink/
---
# Get-JiraIssueLink

## SYNOPSIS

Returns a specific issueLink from Jira

## SYNTAX

```powershell
Get-JiraIssueLink -Id <Int32[]> [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

## DESCRIPTION

This function returns information regarding a specified issueLink from Jira.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraIssueLink 10000
```

Returns information about the IssueLink with ID 10000

### EXAMPLE 2

```powershell
Get-JiraIssueLink -IssueLink 10000
```

Returns information about the IssueLink with ID 10000

### EXAMPLE 3

```powershell
(Get-JiraIssue TEST-01).issuelinks | Get-JiraIssueLink
```

Returns the information about all IssueLinks in issue TEST-01

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

### -Id

Runtime numeric connection ID, unique across products for the current shared runtime.

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases: None

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Int[]


## OUTPUTS

### JiraPS.IssueLink

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Add-JiraIssueLink](../Add-JiraIssueLink/)

[Get-JiraIssueLinkType](../Get-JiraIssueLinkType/)

[Remove-JiraIssueLink](../Remove-JiraIssueLink/)
