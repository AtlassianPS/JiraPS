---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraUser/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraUser/
---
# Get-JiraUser

## SYNOPSIS

Returns a user from Jira

## SYNTAX

### Self (Default)

```powershell
Get-JiraUser [-IncludeInactive] [-Credential <pscredential>] [<CommonParameters>]
```

### ByUserName

```powershell
Get-JiraUser [-UserName] <string[]> [-Exact] [-IncludeInactive] [-MaxResults <uint>] [-Skip <ulong>]
 [-Credential <pscredential>] [<CommonParameters>]
```

### ByAccountId

```powershell
Get-JiraUser [-AccountId] <string[]> [-Exact] [-IncludeInactive] [-MaxResults <uint>]
 [-Skip <ulong>] [-Credential <pscredential>] [<CommonParameters>]
```

### ByInputObject

```powershell
Get-JiraUser [-InputObject] <Object[]> [-Exact] [-IncludeInactive] [-Credential <pscredential>]
 [<CommonParameters>]
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

Returns information about all users.
The empty string "" matches all users.

### EXAMPLE 6

```powershell
Get-JiraUser -AccountId "5b10a2844c20165700ede21g"
```

Returns user information for the specified account ID.
Use this on Jira Cloud where
usernames are not available due to GDPR requirements.
The `AccountId` property
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

### -AccountId

Atlassian account ID of the user (used on Jira Cloud).

```yaml
Type: String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByAccountId
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Credential

Credentials to use to connect to JIRA.
If not specified, this function will use anonymous access.

```yaml
Type: PSCredential
DefaultValue: '[System.Management.Automation.PSCredential]::Empty'
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

### -Exact

Limits the search to users where the username or account ID is exactly the term searched for.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByAccountId
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: ByUserName
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: ByInputObject
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IncludeInactive

Include inactive users in the search

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

### -InputObject

User Object of the user.

```yaml
Type: Object[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByInputObject
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -MaxResults

Maximum number of user to be returned.

> The API does not allow for any value higher than 1000.

```yaml
Type: UInt32
DefaultValue: 50
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByAccountId
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: ByUserName
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Skip

Controls how many objects will be skipped before starting output.

Defaults to 0.

```yaml
Type: UInt64
DefaultValue: 0
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByAccountId
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: ByUserName
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -UserName

Name of the user to search for.

```yaml
Type: String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- User
- Name
ParameterSets:
- Name: ByUserName
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### String

Username, name, or e-mail address

### System.String[]

## OUTPUTS

### JiraPS.User

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

**Jira Cloud vs Data Center**: On Jira Cloud, users are identified by `accountId` instead of
`username` due to GDPR requirements.
The returned user object includes both `Name` (username,
may be empty on Cloud) and `AccountId` (always present on Cloud).
When working with Cloud,
use the `AccountId` property for user-related operations like assigning issues.

## RELATED LINKS

[New-JiraUser](../New-JiraUser/)

[Remove-JiraUser](../Remove-JiraUser/)
