---
external help file: JiraPS-help.xml
online version: 
schema: 2.0.0
---

# Get-JiraGroup

## SYNOPSIS
Returns a group from Jira

## SYNTAX

### ByGroupName (Default)
```
Get-JiraGroup [-GroupName] <String[]> [-Credential <PSCredential>]
```

### ByInputObject
```
Get-JiraGroup [-InputObject] <Object[]> [-Credential <PSCredential>]
```

## DESCRIPTION
This function returns information regarding a specified group from JIRA.

By default, this function does not display members of the group. 
This is JIRA's default
behavior as well. 
To display group members, use Get-JiraGroupMember.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-JiraGroup -GroupName testGroup -Credential $cred
```

Returns information about the group "testGroup"

### -------------------------- EXAMPLE 2 --------------------------
```
Get-ADUser -filter "Name -like 'John*Smith'" | Select-Object -ExpandProperty samAccountName | Get-JiraUser -Credential $cred
```

This example searches Active Directory for the username of John W.
Smith, John H.
Smith,
and any other John Smiths, then obtains their JIRA user accounts.

## PARAMETERS

### -GroupName
Name of the group to search for.

```yaml
Type: String[]
Parameter Sets: ByGroupName
Aliases: Name

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject
Object of the group to search for.

```yaml
Type: Object[]
Parameter Sets: ByInputObject
Aliases: 

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
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### [Object[]] The group to look up in JIRA. This can be a String or a JiraPS.Group object.

## OUTPUTS

### [JiraPS.Group]

## NOTES

## RELATED LINKS

