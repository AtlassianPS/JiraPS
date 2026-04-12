---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/New-JiraSession/
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/JiraPS/commands/New-JiraSession/
---
# New-JiraSession

## SYNOPSIS

Creates a persistent JIRA authenticated session which can be used by other JiraPS functions

## SYNTAX

### Credential (Default)

```powershell
New-JiraSession [-Credential <PSCredential>] [-Headers <Hashtable>] [<CommonParameters>]
```

### BearerToken

```powershell
New-JiraSession -BearerToken <SecureString> [-Headers <Hashtable>] [<CommonParameters>]
```

### ApiToken

```powershell
New-JiraSession -ApiToken <SecureString> -EmailAddress <String> [-Headers <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION

This function creates a persistent,
authenticated session in to JIRA which can be used by all other
JiraPS functions instead of explicitly passing parameters.

This removes the need to use the `-Credential` parameter constantly for each function call.

JiraPS supports multiple authentication methods:

- **Credential**: Traditional username/password authentication (Jira Data Center)
- **BearerToken**: Personal Access Token (PAT) authentication (Jira Data Center 8.14+)
- **ApiToken**: API Token authentication with email address (Jira Cloud)

You can find more information in [about_JiraPS_Authentication](../../about/authentication.html)

## EXAMPLES

### EXAMPLE 1

```powershell
New-JiraSession -Credential (Get-Credential jiraUsername)
Get-JiraIssue TEST-01
```

Creates a Jira session for jiraUsername using basic authentication.
The following `Get-JiraIssue` is run using the saved session for jiraUsername.

### EXAMPLE 2

```powershell
$pat = Read-Host -AsSecureString "Enter your PAT"
New-JiraSession -BearerToken $pat
Get-JiraIssue TEST-01
```

Creates a Jira session using a Personal Access Token (PAT) with Bearer authentication.
This is the recommended method for Jira Data Center 8.14 and later.

### EXAMPLE 3

```powershell
$apiToken = Read-Host -AsSecureString "Enter your API token"
New-JiraSession -ApiToken $apiToken -EmailAddress "user@example.com"
Get-JiraIssue TEST-01
```

Creates a Jira session using an API token with your Atlassian account email.
This is the recommended method for Jira Cloud.

### EXAMPLE 4

```powershell
$headers = @{ "X-Custom-Header" = "value" }
New-JiraSession -BearerToken $pat -Headers $headers
```

Creates a Jira session with a PAT and additional custom headers.

## PARAMETERS

### -Credential

Credentials to use to connect to JIRA using basic authentication.

```yaml
Type: PSCredential
Parameter Sets: Credential
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BearerToken

A Personal Access Token (PAT) for Bearer token authentication.
Use this for Jira Data Center 8.14 and later.

Create a PAT in Jira: Profile > Personal Access Tokens > Create token

```yaml
Type: SecureString
Parameter Sets: BearerToken
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApiToken

An API token for Jira Cloud authentication.
Must be used together with `-EmailAddress`.

Create an API token at: https://id.atlassian.com/manage-profile/security/api-tokens

```yaml
Type: SecureString
Parameter Sets: ApiToken
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EmailAddress

The email address associated with your Atlassian account.
Required when using `-ApiToken` for Jira Cloud authentication.

```yaml
Type: String
Parameter Sets: ApiToken
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Headers

Additional headers to include in requests.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: @{}
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [PSCredential]

## OUTPUTS

### [JiraPS.Session]

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[about_JiraPS_Authentication](../../about/authentication.html)

[Get-JiraSession](../Get-JiraSession/)
