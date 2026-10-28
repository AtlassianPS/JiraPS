---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/New-JiraSession/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/New-JiraSession/
---
# New-JiraSession

## SYNOPSIS

Open a Jira connection through the legacy command name.

## SYNTAX

```powershell
New-JiraSession [[-Name] <string>] [[-Uri] <uri>] [[-Credential] <pscredential>] [[-EmailAddress] <string>] [[-ApiToken] <Object>] [[-PersonalAccessToken] <Object>] [[-Headers] <hashtable>] [-Anonymous] [-Default] [<CommonParameters>]
```

## DESCRIPTION

Open a Jira connection through the legacy command name.

This compatibility name uses the shared connection implementation.
It does not retain the v2 singleton or AtlassianPS.JiraPS.Session return type.
Deployment detection and validation follow Connect-Jira, including its authenticated fallback when serverInfo is unavailable.
Anonymous connections require recognized deployment metadata from /rest/api/2/serverInfo.

## EXAMPLES

### EXAMPLE 1

```powershell
New-JiraSession -PersonalAccessToken $env:JIRA_PAT
```

Reuse the current default endpoint or configured migration endpoint and allocate a unique name.
Existing defaults remain unchanged unless Default is supplied.

## PARAMETERS

### -Name

Friendly connection name, unique without case sensitivity within Jira.

```yaml
Type: String
Parameter Sets: (All)
Aliases: None

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Uri

Jira endpoint for the new connection.
When omitted, uses the current default connection's endpoint or the configured Jira server URL.
Normal HTTPS commercial Atlassian site URLs resolve cloudId and the API gateway automatically for ApiToken authentication.

```yaml
Type: Uri
Parameter Sets: (All)
Aliases: None

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential

Username/password or compatible Cloud email/token as PSCredential for the new connection.
An empty credential fails.
The command requires explicit authentication even when reusing the default endpoint.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases: None

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EmailAddress

Cloud authentication email for ApiToken.
Supply both the email address and token when creating the connection.

```yaml
Type: String
Parameter Sets: (All)
Aliases: None

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApiToken

Cloud API token as a nonempty string or SecureString.
Supply the authentication email in the same call.
The module normalizes the secret and resolves a normal Cloud site URL automatically.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: None

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PersonalAccessToken

Data Center PAT as a nonempty string or SecureString.
PAT and BearerToken are aliases.
No dummy username is required.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: PAT, BearerToken

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Anonymous

Explicit anonymous authentication when the Jira endpoint permits it.
Requires recognized deployment metadata from /rest/api/2/serverInfo.
Never borrows the default connection identity.

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

Select the new connection as the Jira default after successful validation.
The first connection becomes the default automatically.
Later connections preserve the selected default unless this switch is supplied.

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

### -Headers

Retained for compatibility with calls that supply an empty hashtable.
Nonempty headers are rejected.
Use Invoke-JiraMethod -Headers for ordinary request headers and explicit authentication parameters when connecting.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases: None

Required: False
Position: 6
Default value: '@{}'
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

Supports standard PowerShell common parameters.

## INPUTS

### None

## OUTPUTS

### AtlassianPS.Connection

## NOTES

Connections belong to one runspace and are never persisted as profiles.

## RELATED LINKS

[Shared authentication](https://atlassianps.org/docs/AtlassianPS.Configuration/about/authentication.html)

[Jira authentication](https://atlassianps.org/docs/JiraPS/about/authentication.html)
