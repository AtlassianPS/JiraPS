---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Add-JiraGroupMember/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Add-JiraGroupMember/
---
# Add-JiraGroupMember

## SYNOPSIS

Adds a user to a JIRA group

## SYNTAX

```powershell
Add-JiraGroupMember [-Group] <Object[]> [-UserName] <Object[]> [[-Session] <PSObject>] [-PassThru]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function adds a JIRA user to a JIRA group.

## EXAMPLES

### EXAMPLE 1

```powershell
Add-JiraGroupMember -Group testUsers -User jsmith
```

This example adds the user "jsmith" to the group "testUsers"

### EXAMPLE 2

```powershell
Get-JiraGroup 'Project Admins' | Add-JiraGroupMember -User jsmith
```

This example illustrates the use of the pipeline to add "jsmith" to the
"Project Admins" group in JIRA.

## PARAMETERS

### -Group

Group (or list of groups) to which the user(s) will be added.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases: GroupName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -UserName

Username or user object obtained from Get-JiraUser.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Session

Session to use to connect to JIRA.  
If not specified, this function will use default session.
The name of a session, PSCredential object or session's instance itself is accepted to pass as value for the parameter.

```yaml
Type: psobject
Parameter Sets: (All)
Aliases: Credential

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru

Whether output should be provided after invoking this function.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [JiraPS.Group[]]

Group(s) to which users should be added

## OUTPUTS

### [JiraPS.Group]

If the `-PassThru` parameter is provided, this function will provide a reference to the JIRA group modified.
Otherwise, this function does not provide output.

## NOTES

This REST method is still marked Experimental in JIRA's REST API.
That means that there is a high probability this will break in future versions of JIRA.
The function will need to be re-written at that time.

This function requires either the `-Session` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraGroup](../Get-JiraGroup/)

[Get-JiraGroupMember](../Get-JiraGroupMember/)

[Get-JiraUser](../Get-JiraUser/)

[New-JiraGroup](../New-JiraGroup/)

[New-JiraUser](../New-JiraUser/)

[Remove-JiraGroupMember](../Remove-JiraGroupMember/)

[Remove-JiraIssue](../Remove-JiraIssue/)

[Set-JiraIssue](../Set-JiraIssue/)
