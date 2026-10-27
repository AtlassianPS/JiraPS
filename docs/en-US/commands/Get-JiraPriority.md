---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraPriority/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraPriority/
---
# Get-JiraPriority

## SYNOPSIS

Returns information about the available priorities in JIRA.

## SYNTAX

### _All (Default)

```powershell
Get-JiraPriority [-Force] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

### _Search

```powershell
Get-JiraPriority -Id <Int32[]> [-Force] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

## DESCRIPTION

This function retrieves all the available Priorities on the JIRA server an returns them as `JiraPS.Priority`.

This function can restrict the output to a subset of the available IssueTypes if told so.

Results are cached for 60 minutes to improve performance.
Use `-Force` to bypass the cache and fetch fresh data.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraPriority
```

This example returns all the IssueTypes on the JIRA server.

### EXAMPLE 2

```powershell
Get-JiraPriority -ID 1
```

This example returns only the Priority with ID 1.

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

### -Force

Bypass the cache and fetch fresh data from the server.

```yaml
Type: SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
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

### -Id

Runtime numeric connection ID, unique across products for the current shared runtime.

```yaml
Type: Int32[]
Parameter Sets: _Search
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

## OUTPUTS

### JiraPS.Priority

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

Remaining operations for `priority` have not yet been implemented in the module.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)
