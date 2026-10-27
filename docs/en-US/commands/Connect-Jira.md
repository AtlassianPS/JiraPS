---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Connect-Jira/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Connect-Jira/
---
# Connect-Jira

## SYNOPSIS

Validate and open a named Jira connection.

## SYNTAX

### Uri (Default)

```powershell
Connect-Jira -Name <String> -Uri <Uri> [-Credential <PSCredential>] [-EmailAddress <String>] [-ApiToken <Object>] [-PersonalAccessToken <Object>] [-Anonymous] [-Default] [<CommonParameters>]
```

### Profile

```powershell
Connect-Jira -Name <String> -Profile <String> [-Credential <PSCredential>] [-EmailAddress <String>] [-ApiToken <Object>] [-PersonalAccessToken <Object>] [-Anonymous] [-Default] [<CommonParameters>]
```

## DESCRIPTION

Create and return a named AtlassianPS.Connection after validating the Jira deployment and, for authenticated connections, the current user.
Supply exactly one authentication method: Credential, EmailAddress with ApiToken, PersonalAccessToken, or Anonymous.
Authentication is supplied for the new connection; it is never borrowed from an existing connection or a saved profile.

Pass the returned object to Jira commands through Connection.
The first successful connection becomes the Jira default, so subsequent commands can omit Connection.
Later connections preserve the existing default unless Default is supplied.

## EXAMPLES

### EXAMPLE 1

```powershell
$work = Connect-Jira -Name work -Uri 'https://work.atlassian.net' -EmailAddress 'me@example.com' -ApiToken $env:JIRA_API_TOKEN
Get-JiraIssue -Key PROJ-1 -Connection $work
```

Connect to Jira Cloud and retrieve an issue using the returned connection.
Use the normal Cloud site URL; discovery identifies the site and resolves the API gateway.

### EXAMPLE 2

```powershell
$token = Read-Host 'Jira PAT' -AsSecureString
$internal = Connect-Jira -Name internal -Uri 'https://jira.example.com/jira' -PersonalAccessToken $token
Get-JiraProject -Connection $internal
```

Connect to Data Center using a masked PAT input and list accessible projects.

### EXAMPLE 3

```powershell
Add-AtlassianServerConfiguration -Name work -Type Jira -Uri 'https://work.atlassian.net'
$work = Connect-Jira -Name work -Profile work -EmailAddress 'me@example.com' -ApiToken (Get-Secret JiraToken)
Get-JiraIssue -Key PROJ-1 -Connection $work
```

Save a non-secret endpoint profile, supply its token from a secret vault, and retrieve an issue.
Get-Secret requires Microsoft.PowerShell.SecretManagement and a configured vault; the vault module is optional.
The profile stores endpoint settings, so each new connection still needs authentication.

### EXAMPLE 4

```powershell
$credential = Get-Credential
$internal = Connect-Jira -Name internal -Uri 'https://jira.example.com/jira' -Credential $credential
Get-JiraIssue -Key PROJ-1 -Connection $internal
```

Connect to Data Center with a username and password, then retrieve an issue through that connection.

### EXAMPLE 5

```powershell
$public = Connect-Jira -Name public -Uri 'https://jira.example.com' -Anonymous
Get-JiraProject -Connection $public
```

Create an anonymous connection and list publicly accessible projects.
The Jira endpoint and requested operation must permit anonymous access.

## PARAMETERS

### -Name

Friendly connection name, unique without case sensitivity within Jira.

```yaml
Type: String
Parameter Sets: (All)
Aliases: None

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Uri

Jira endpoint for the new connection.
Supply the normal HTTPS Jira Cloud site URL when using ApiToken; site discovery resolves the API gateway automatically.
For Data Center, include any Jira context path, such as /jira.
Uri and Profile cannot be combined.

```yaml
Type: Uri
Parameter Sets: Uri
Aliases: None

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Profile

Name of a saved Jira endpoint profile.
Create profiles with Add-AtlassianServerConfiguration.
Connect-Jira copies the endpoint and ignores saved Session values.
Remove legacy profile headers and certificates before connecting, and supply authentication explicitly.

```yaml
Type: String
Parameter Sets: Profile
Aliases: None

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

Credential for the new connection: Data Center username/password or compatible Jira Cloud email/API token.
Both the username and password must be nonempty; null or empty credentials fail.
If Credential is omitted, supply another authentication method.
For automatic Cloud site discovery and scoped-token routing, use EmailAddress with ApiToken.

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

### -EmailAddress

Jira Cloud authentication email to use with ApiToken in the same call.
Email is an alias.
EmailAddress cannot be used with another authentication method.

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

### -Default

Select the successfully validated new connection as the Jira default.
The first successful connection becomes the default automatically.
Later connections preserve an existing default unless this switch is supplied.

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

Supports standard PowerShell common parameters.

## INPUTS

### None

This command does not accept pipeline input.

## OUTPUTS

### AtlassianPS.Connection

## NOTES

Connections belong to one runspace and are never persisted as profiles.

## RELATED LINKS

[Shared authentication](https://atlassianps.org/docs/AtlassianPS.Configuration/about/authentication.html)

[Jira authentication](https://atlassianps.org/docs/JiraPS/about/authentication.html)
