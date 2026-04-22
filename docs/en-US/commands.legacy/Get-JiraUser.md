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
Get-JiraUser [-UserName] <String[]> [-IncludeInactive] [[-MaxResults] <UInt32>] [[-Skip] <UInt64>] [-Credential <PSCredential>] [-Exact] [<CommonParameters>]
```

### ByAccountId

```powershell
Get-JiraUser [-AccountId] <String[]> [-IncludeInactive] [[-MaxResults] <UInt32>] [[-Skip] <UInt64>] [-Credential <PSCredential>] [-Exact] [<CommonParameters>]
```

### ByInputObject

```powershell
Get-JiraUser [-InputObject] <Object[]> [-IncludeInactive] [-Credential <PSCredential>] [-Exact] [<CommonParameters>]
```

## DESCRIPTION

This function returns information regarding a specified user from Jira.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraUser -UserName user1
```

Returns information about all users with username like user1

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

### EXAMPLE 4

```powershell 
Get-JiraUser -UserName user1 -Exact
```

Returns information about user user1

### EXAMPLE 5

```powershell
Get-JiraUser -UserName ""
```

Returns information about all users. The empty string "" matches all users.

### EXAMPLE 6

```powershell
Get-JiraUser -AccountId "5b10a2844c20165700ede21g"
```

Returns user information for the specified account ID. Use this on Jira Cloud where
usernames are not available due to GDPR requirements. The `AccountId` property
can then be used in other commands like `Set-JiraIssue -Assignee`.

### EXAMPLE 7

```powershell
# Find a user by display name and get their accountId for Cloud
$user = Get-JiraUser -UserName "John Smith" | Select-Object -First 1
Set-JiraIssue TEST-1 -Assignee $user.AccountId
```

Searches for a user by name, then uses their account ID to assign an issue.
This pattern is useful when migrating scripts from Data Center to Cloud.

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

### -AccountId

Atlassian account ID of the user (used on Jira Cloud).

```yaml
Type: String[]
Parameter Sets: ByAccountId
Aliases:

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

### -Exact

Limits the search to users where the username or account ID is exactly the term searched for.

```yaml
Type: Switch
Parameter Sets: ByUserName, ByAccountId, ByInputObject
Aliases:

Required: False
Position: Named
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

### -MaxResults

Maximum number of user to be returned.

> The API does not allow for any value higher than 1000.

```yaml
Type: UInt32
Parameter Sets: ByUserName, ByAccountId
Aliases:

Required: False
Position: Named
Default value: 50
Accept pipeline input: False
Accept wildcard characters: False
```

### -Skip

Controls how many objects will be skipped before starting output.

Defaults to 0.

```yaml
Type: UInt64
Parameter Sets: ByUserName, ByAccountId
Aliases:

Required: False
Position: Named
Default value: 0
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

**Jira Cloud vs Data Center**: On Jira Cloud, users are identified by `accountId` instead of
`username` due to GDPR requirements. The returned user object includes both `Name` (username,
may be empty on Cloud) and `AccountId` (always present on Cloud). When working with Cloud,
use the `AccountId` property for user-related operations like assigning issues.

## RELATED LINKS

[New-JiraUser](../New-JiraUser/)

[Remove-JiraUser](../Remove-JiraUser/)
