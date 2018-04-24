---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraGroup/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraGroup/
---
# Get-JiraGroup

## SYNOPSIS

Returns a group from Jira

## SYNTAX

```powershell
Get-JiraGroup [-GroupName] <String[]> [[-Credential] <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

This function returns information regarding a specified group from JIRA.

To get the members of a group, use `Get-JiraGroupMember`.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraGroup -GroupName testGroup
```

Returns information about the group "testGroup"

### EXAMPLE 2

```powershell
Get-JiraGroup -GroupName testGroup |
    Get-JiraGroupMember
```

This example retrieves the members of "testGroup".

## PARAMETERS

### -GroupName

Name of the group to search for.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Name

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Credential

Credentials to use to connect to JIRA.  
If not specified, this function will use anonymous access.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [JiraPS.Group]

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Get-JiraGroupMember](../Get-JiraGroupMember/)

[Get-JiraUser](../Get-JiraUser/)

[New-JiraGroup](../New-JiraGroup/)

[Remove-JiraGroup](../Remove-JiraGroup/)
