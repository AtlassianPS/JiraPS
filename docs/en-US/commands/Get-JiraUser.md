---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraUser/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraUser/
---
# Get-JiraUser

## SYNOPSIS

Returns a user from Jira

## SYNTAX

### Self (Default)

```powershell
Get-JiraUser [-Credential <PSCredential>] [<CommonParameters>]
```

### ByUserName

```powershell
Get-JiraUser [-UserName] <String[]> [-IncludeInactive] [-Credential <PSCredential>] [<CommonParameters>]
```

### ByInputObject

```powershell
Get-JiraUser [-InputObject] <Object[]> [-IncludeInactive] [-Credential <PSCredential>] [<CommonParameters>]
```

## DESCRIPTION

This function returns information regarding a specified user from Jira.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraUser -UserName user1
```

Returns information about the user user1

### EXAMPLE 2

```powershell
Get-ADUser -filter "Name -like 'John*Smith'" | Select-Object -ExpandProperty samAccountName | Get-JiraUser -Credential $cred
```

This example searches Active Directory for "John*Smith", then obtains their JIRA user accounts.

### EXAMPLE 3

```powershell
Get-JiraUser -Credential $cred
```

This example returns the JIRA user that is executing the command.

## PARAMETERS

### -UserName

Name of the user to search for.

```yaml
Type: String[]
Parameter Sets: ByUserName
Aliases: User, Name

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -InputObject

User Object of the user.

```yaml
Type: Object[]
Parameter Sets: ByInputObject
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeInactive

Include inactive users in the search

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

### -Credential

Credentials to use to connect to JIRA.
If not specified, this function will use anonymous access.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

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

### [String[]]

Username, name, or e-mail address

## OUTPUTS

### [JiraPS.User]

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[New-JiraUser](../New-JiraUser/)

[Remove-JiraUser](../Remove-JiraUser/)
