---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueType/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueType/
---
# Get-JiraIssueType

## SYNOPSIS

Returns information about the available issue type in Jira.

## SYNTAX

### _All (Default)

```powershell
Get-JiraIssueType [-Force] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [-ConnectionName <String>] [-Uri <Uri>] [-EmailAddress <String>] [-ApiToken <Object>] [-PersonalAccessToken <Object>] [-Anonymous] [<CommonParameters>]
```

### _Search

```powershell
Get-JiraIssueType -IssueType <AtlassianPS.JiraPS.IssueType[]> [-Force] [-Credential <PSCredential>] [-Connection <AtlassianPS.Connection>] [-ConnectionName <String>] [-Uri <Uri>] [-EmailAddress <String>] [-ApiToken <Object>] [-PersonalAccessToken <Object>] [-Anonymous] [<CommonParameters>]
```

## DESCRIPTION

This function retrieves all the available IssueType on the Jira server an returns them as `AtlassianPS.JiraPS.IssueType`.

This function can restrict the output to a subset of the available IssueTypes if told so.

Results are cached for 60 minutes to improve performance.
Use `-Force` to bypass the cache and fetch fresh data.

## EXAMPLES

### Example 1

```powershell
Get-JiraIssueType
```

This example returns all the IssueTypes on the Jira server.

### Example 2

```powershell
Get-JiraIssueType -IssueType 'Bug'
```

This example returns only the IssueType "Bug".

### Example 3

```powershell
Get-JiraIssueType -IssueType 'Bug','Task','4'
```

This example return the information about the IssueType named "Bug" and "Task" and with ID "4".

## PARAMETERS

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

### -Force

Bypass the cache and fetch fresh data from the server.

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

### -IssueType

Issue type objects, IDs or wildcard issue type names.
An object with an ID selects that exact issue type.

```yaml
Type: AtlassianPS.JiraPS.IssueType[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: _Search
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
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

### AtlassianPS.JiraPS.IssueType

Pipe an issue type object to retrieve its current details.

### System.String

Pipe an issue type name or ID.

### System.Int64

Pipe a numeric issue type ID.

## OUTPUTS

### AtlassianPS.JiraPS.IssueType

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent Jira session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to Jira.

## RELATED LINKS

[Get-JiraIssue](../Get-JiraIssue/)
