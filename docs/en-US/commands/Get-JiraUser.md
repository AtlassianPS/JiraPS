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

Returns a user from Jira.

## SYNTAX

### Self (Default)

```powershell
Get-JiraUser [-IncludeInactive] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [-ConnectionName <String>] [-Uri <Uri>] [-EmailAddress <String>] [-ApiToken <Object>] [-PersonalAccessToken <Object>] [-Anonymous] [<CommonParameters>]
```

### ByUserName

```powershell
Get-JiraUser -UserName <String[]> [-Exact] [-IncludeInactive] [-MaxResults <UInt32>] [-Skip <UInt64>] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [-ConnectionName <String>] [-Uri <Uri>] [-EmailAddress <String>] [-ApiToken <Object>] [-PersonalAccessToken <Object>] [-Anonymous] [<CommonParameters>]
```

### ByAccountId

```powershell
Get-JiraUser -AccountId <String[]> [-Exact] [-IncludeInactive] [-MaxResults <UInt32>] [-Skip <UInt64>] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [-ConnectionName <String>] [-Uri <Uri>] [-EmailAddress <String>] [-ApiToken <Object>] [-PersonalAccessToken <Object>] [-Anonymous] [<CommonParameters>]
```

### ByInputObject

```powershell
Get-JiraUser -InputObject <AtlassianPS.JiraPS.User[]> [-Exact] [-IncludeInactive] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [-ConnectionName <String>] [-Uri <Uri>] [-EmailAddress <String>] [-ApiToken <Object>] [-PersonalAccessToken <Object>] [-Anonymous] [<CommonParameters>]
```

## DESCRIPTION

This function returns information regarding a specified user from Jira.

## EXAMPLES

### Example 1

```powershell
Get-JiraUser -UserName user1
```

Returns information about all users with username like user1

### Example 2

```powershell
Get-ADUser -filter "Name -like 'John*Smith'" | Select-Object -ExpandProperty samAccountName | Get-JiraUser -Credential $cred
```

This example searches Active Directory for "John*Smith", then obtains their Jira user accounts.

### Example 3

```powershell
Get-JiraUser -Credential $cred
```

This example returns the Jira user that is executing the command.

### Example 4

```powershell
Get-JiraUser -UserName user1 -Exact
```

Returns information about user user1

### Example 5

```powershell
Get-JiraUser -UserName ''
```

Returns information about all users.
The empty string "" matches all users.

### Example 6

```powershell
Get-JiraUser -AccountId '5b10a2844c20165700ede21g'
```

Returns user information for the specified account ID.
Use this on Jira Cloud where usernames are not available due to GDPR requirements.
The `AccountId` property can then be used in other commands like `Set-JiraIssue -Assignee`.

### Example 7

```powershell
# Find a user by display name and get their accountId for Cloud
$user = Get-JiraUser -UserName 'John Smith' | Select-Object -First 1
Set-JiraIssue TEST-1 -Assignee $user.AccountId
```

Searches for a user by name, then uses their account ID to assign an issue.
This pattern is useful when migrating scripts from Data Center to Cloud.

### Example 8

```powershell
Get-JiraUser -UserName user1 | Get-JiraUser
```

Refreshes user objects by piping existing `AtlassianPS.JiraPS.User` output back through `Get-JiraUser`.
Use `-UserName` / `-AccountId` for string-based lookups, and `-InputObject` when requerying existing user objects.

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

Username/password or compatible Cloud email/token as PSCredential. Explicit input temporarily overrides the selected identity without inheriting cookies or changing the stored connection. An empty credential fails; omitted input uses the selected connection.

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

Include inactive users in the search.

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

User object(s) to refresh from Jira.
Use this parameter when you already have `AtlassianPS.JiraPS.User` objects and want to requery the latest data.
For string-based lookup, use `-UserName` (Data Center / generic) or `-AccountId` (Cloud).

```yaml
Type: AtlassianPS.JiraPS.User[]
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

### -Connection

Live shared connection for this operation. Session is a compatibility alias. The object must be active in this runspace and belong to Jira.

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

### -ConnectionName

Case-insensitive name of an active Jira connection. Server and ServerName are compatibility aliases. This parameter is mutually exclusive with Connection and a standalone endpoint.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Server, ServerName

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Uri

Standalone Jira product endpoint for this logical operation. Cannot be combined with Connection or ConnectionName. Supply one explicit authentication mode; use Anonymous for anonymous access. Normal HTTPS commercial Atlassian site URLs resolve cloudId and the API gateway automatically for ApiToken authentication.

```yaml
Type: Uri
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EmailAddress

Cloud authentication email for ApiToken. Email is an alias. An override must supply both its own email and token.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Email

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApiToken

Cloud API token as a nonempty string or SecureString. Supply the authentication email in the same call. The module normalizes the secret and resolves a normal Cloud site URL automatically.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: None

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PersonalAccessToken

Data Center PAT as a nonempty string or SecureString. PAT and BearerToken are aliases. No dummy username is required.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: PAT, BearerToken

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Anonymous

Explicit anonymous authentication when the Jira endpoint permits it. Never borrows the default connection identity.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: None

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

### String[]

Username, name, or e-mail address

### AtlassianPS.JiraPS.User[]

Existing user object(s) to refresh from Jira via `-InputObject`.

## OUTPUTS

### AtlassianPS.JiraPS.User

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent Jira session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to Jira.

**Jira Cloud vs Data Center**: On Jira Cloud, users are identified by `accountId` instead of `username` due to GDPR requirements.
The returned user object includes both `Name` (username, may be empty on Cloud) and `AccountId` (always present on Cloud).
When working with Cloud, use the `AccountId` property for user-related operations like assigning issues.

## RELATED LINKS

[New-JiraUser](../New-JiraUser/)

[Remove-JiraUser](../Remove-JiraUser/)
