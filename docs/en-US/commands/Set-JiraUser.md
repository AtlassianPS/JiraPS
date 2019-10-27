---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Set-JiraUser/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/Set-JiraUser/
---
# Set-JiraUser

## SYNOPSIS

Modifies user properties in JIRA

## SYNTAX

### ByNamedParameters (Default)

```powershell
Set-JiraUser [-User] <Object[]> [-DisplayName <String>] [-EmailAddress <String>] [[-Active] <Boolean>]
 [-Session <PSObject>] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]

### ByHashtable

```powershell
Set-JiraUser [-User] <Object[]> [-Property] <Hashtable> [-Session <PSObject>] [-PassThru] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

This function modifies user properties in JIRA, allowing you to change a user's
e-mail address, display name, and any other properties supported by JIRA's API.

## EXAMPLES

### EXAMPLE 1

```powershell
Set-JiraUser -User user1 -EmailAddress user1_new@example.com
```

Modifies user1's e-mail address to a new value.
The original value is overridden.

### EXAMPLE 2

```powershell
Set-JiraUser -User user2 -Properties @{EmailAddress='user2_new@example.com';DisplayName='User 2'}
```

This example modifies a user's properties using a hashtable.
This allows updating properties that are not exposed as parameters to this function.

## PARAMETERS

### -User

Username or user object obtained from `Get-JiraUser`.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases: UserName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -DisplayName

Display name to set.

```yaml
Type: String
Parameter Sets: ByNamedParameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EmailAddress

E-mail address to set.

```yaml
Type: String
Parameter Sets: ByNamedParameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Active

Sets user to active or inactive.

```yaml
Type: Boolean
Parameter Sets: ByNamedParameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Property

Hashtable (dictionary) of additional information to set.

```yaml
Type: Hashtable
Parameter Sets: ByHashtable
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
Position: Named
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

### [JiraPS.User]

## OUTPUTS

### [JiraPS.User]

If the `-PassThru` parameter is provided, this function will provide a reference
to the JIRA user modified.  Otherwise, this function does not provide output.

## NOTES

The `-Active` parameter is supported only in Jira Server version 8.3.0 and above.

This function requires either the `-Session` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[New-JiraUser](../New-JiraUser/)

[Get-JiraUser](../Get-JiraUser/)
