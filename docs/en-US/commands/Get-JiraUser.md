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
Get-JiraUser [-Connection <AtlassianPS.Connection>] [-IncludeTotalCount] [-Skip <ulong>] [-First <ulong>] [<CommonParameters>]
```

### User

```powershell
Get-JiraUser [-User] <AtlassianPS.JiraPS.User[]> [-Connection <AtlassianPS.Connection>] [-IncludeTotalCount] [-Skip <ulong>]
 [-First <ulong>] [<CommonParameters>]
```

### Query

```powershell
Get-JiraUser -Query <string> [-IncludeInactive] [-PageSize <int>] [-Connection <AtlassianPS.Connection>]
 [-IncludeTotalCount] [-Skip <ulong>] [-First <ulong>] [<CommonParameters>]
```

### All

```powershell
Get-JiraUser -All [-PageSize <int>] [-Connection <AtlassianPS.Connection>] [-IncludeTotalCount] [-Skip <ulong>]
 [-First <ulong>] [<CommonParameters>]
```

## ALIASES

## DESCRIPTION

Returns the current user, exact users, explicit search results or an intentional user enumeration.
User identifiers remain opaque: Cloud uses accountId and Data Center uses username.
Query and All support First, Skip, PageSize and IncludeTotalCount.
Cloud user search is limited to the first 1,000 matches.
Data Center search limits depend on Jira's version.
Data Center enumeration requires /rest/api/2/user/list and follows its cursor.
Unavailable enumeration fails with guidance to use Query.

## EXAMPLES

### Example 1

```powershell
Get-JiraUser
```

Return the authenticated current user.

### Example 2

```powershell
Get-JiraUser -User 'opaque-account-id'
```

Look up one exact Cloud account ID.
Use a literal username with a Data Center connection.

### Example 3

```powershell
Get-JiraUser -Query 'John Smith' -First 10 -PageSize 25
```

Search explicitly and return at most ten matching users.

### Example 4

```powershell
Get-JiraUser -All -Skip 20 -First 10
```

Enumerate users intentionally and skip the first twenty records.

### Example 5

```powershell
Get-JiraUser -Query 'John Smith' | Get-JiraUser
```

Refresh each returned user through its exact deployment-specific identity.

## PARAMETERS

### -All

Enumerate Jira users explicitly.
Cloud includes active, inactive and previously deleted accounts.
Data Center requires a supported /user/list endpoint.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: All
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Connection

Active Jira connection for this operation.
When omitted, the command uses the selected Jira default.
Create connections with Connect-Jira; resolve names with Get-JiraConnection -Name.

```yaml
Type: AtlassianPS.Connection
DefaultValue: None
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

### -First

Maximum number of matching records to return.

```yaml
Type: UInt64
DefaultValue: ''
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

### -IncludeInactive

Include inactive users in Data Center searches.
Cloud search returns active users only; use All for other accounts.

```yaml
Type: SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Query
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IncludeTotalCount

Return total-count information before the records.
Accuracy is unknown when Jira does not provide a total.

```yaml
Type: SwitchParameter
DefaultValue: ''
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

### -PageSize

Number of records requested per page.
Use First to limit output and Skip to skip records.

```yaml
Type: Int32
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: All
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: Query
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Query

Search for users explicitly.
Cloud uses the user/search query; Data Center uses the username search.
Search results do not trigger an extra request per user.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Query
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Skip

Number of matching records to skip before returning output.

```yaml
Type: UInt64
DefaultValue: 0
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

### -User

Exact user identifiers or typed user objects.
Cloud strings are literal account IDs; Data Center strings are literal usernames.

```yaml
Type: AtlassianPS.JiraPS.User[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: User
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
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

### AtlassianPS.JiraPS.User[]

## OUTPUTS

### AtlassianPS.JiraPS.User

## NOTES

This function uses the selected Jira connection unless you pass another connection through `-Connection`.
Use `Connect-Jira` to create a connection.
For anonymous access, create the connection with `Connect-Jira -Anonymous`.

**Jira Cloud vs Data Center**: On Jira Cloud, users are identified by `accountId` instead of `username` due to GDPR requirements.
The returned user object includes both `Name` (username, may be empty on Cloud) and `AccountId` (always present on Cloud).
When working with Cloud, use the `AccountId` property for user-related operations like assigning issues.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[New-JiraUser](../New-JiraUser/)

[Remove-JiraUser](../Remove-JiraUser/)
