---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Get-JiraUser

## SYNOPSIS
Returns a user from Jira

## SYNTAX

### ByUserName (Default)
```
Get-JiraUser [-UserName] <String[]> [-IncludeInactive] [-Credential <PSCredential>]
```

### ByInputObject
```
Get-JiraUser [-InputObject] <Object[]> [-IncludeInactive] [-Credential <PSCredential>]
```

## DESCRIPTION
This function returns information regarding a specified user from Jira.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-JiraUser -UserName user1 -Credential $cred
```

Returns information about the user user1

### -------------------------- EXAMPLE 2 --------------------------
```
Get-ADUser -filter "Name -like 'John*Smith'" | Select-Object -ExpandProperty samAccountName | Get-JiraUser -Credential $cred
```

This example searches Active Directory for the username of John W.
Smith, John H.
Smith,
and any other John Smiths, then obtains their JIRA user accounts.

## PARAMETERS

### -UserName
Username, name, or e-mail address of the user.
Any of these should
return search results from Jira.

```yaml
Type: String[]
Parameter Sets: ByUserName
Aliases: User, Name

Required: True
Position: 1
Default value: None
Accept pipeline input: False
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

## INPUTS

### [String[]] Username
[PSCredential] Credentials to use to connect to Jira

## OUTPUTS

### [JiraPS.User]

## NOTES

## RELATED LINKS

