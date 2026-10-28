---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraFilterPermission/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraFilterPermission/
---
# Get-JiraFilterPermission

## SYNOPSIS

Fetch the permissions of a specific filter.

## SYNTAX

```powershell
Get-JiraFilterPermission [-Filter] <AtlassianPS.JiraPS.Filter[]> [-Credential <pscredential>] [-Connection <AtlassianPS.Connection>] [<CommonParameters>]
```

## DESCRIPTION

This allows the user to retrieve all the sharing permissions set for a filter.

## EXAMPLES

### Example 1

```powershell
Get-JiraFilterPermission -Filter (Get-JiraFilter 12345)
# Or use the ID directly.
Get-JiraFilterPermission -Id 12345
```

Two methods for retrieving the permissions set for filter 12345.

### Example 2

```powershell
12345 | Get-JiraFilterPermission
# Or use the ID directly.
Get-JiraFilter 12345 | Get-JiraFilterPermission
```

Two methods for retrieving the permissions set for filter 12345 by using the pipeline.

The ID can be read from a file.

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

### -Filter

Filter objects or positive numeric filter IDs whose permissions are retrieved.
Accepts numeric strings and pipeline input.
`Id` is an alias for `Filter`.

```yaml
Type: AtlassianPS.JiraPS.Filter[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
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

### AtlassianPS.JiraPS.Filter


## OUTPUTS

### AtlassianPS.JiraPS.Filter

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraFilter](../Get-JiraFilter/)

[Add-JiraFilterPermission](../Add-JiraFilterPermission/)

[Remove-JiraFilterPermission](../Remove-JiraFilterPermission/)
