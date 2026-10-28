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
New-JiraSession [-Name <String>] [-Uri <Uri>] [-Credential <PSCredential>] [-EmailAddress <String>] [-ApiToken <Object>] [-PersonalAccessToken <Object>] [-Anonymous] [-Default] [-Headers <Hashtable>] [-DeploymentType <String>] [<CommonParameters>]
```

## DESCRIPTION

Open a Jira connection through the legacy command name.

This compatibility name uses the shared connection implementation.
It does not retain the v2 singleton or AtlassianPS.JiraPS.Session return type.
Deployment detection and validation follow Connect-Jira, including its fallback when serverInfo is unavailable.

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
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Uri

Standalone Jira product endpoint for this logical operation.
Cannot be combined with Connection or ConnectionName.
Supply one explicit authentication mode; use Anonymous for anonymous access.
Normal HTTPS commercial Atlassian site URLs resolve cloudId and the API gateway automatically for ApiToken authentication.

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

### -Credential

Username/password or compatible Cloud email/token as PSCredential.
Explicit input temporarily overrides the selected identity without inheriting cookies or changing the stored connection.
An empty credential fails; omitted input uses the selected connection.

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

Cloud authentication email for ApiToken.
Email is an alias.
An override must supply both its own email and token.

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

Cloud API token as a nonempty string or SecureString.
Supply the authentication email in the same call.
The module normalizes the secret and resolves a normal Cloud site URL automatically.

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

Data Center PAT as a nonempty string or SecureString.
PAT and BearerToken are aliases.
No dummy username is required.

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

Explicit anonymous authentication when the Jira endpoint permits it.
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

### -DeploymentType

Optional deployment information when serverInfo is unavailable.
Accepted values are Cloud, Server and Data Center.
Returned metadata takes precedence; contradictory Cloud versus Server/Data Center evidence fails.
Authenticated connections always validate the identity through myself.
Anonymous fallback requires this parameter and a recognizable, nonempty anonymous project-list response.

```yaml
Type: String
Parameter Sets: (All)
Aliases: None

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Default

Select the successful new connection as Jira default, or filter the listing to the current default.
The first successful connection selects itself automatically; later connections leave an existing default unchanged unless this switch is supplied.

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

Ordinary request headers.
Authorization and Cookie headers are rejected; supply authentication through the supported parameters.

```yaml
Type: Hashtable
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

### AtlassianPS.Connection

## OUTPUTS

### AtlassianPS.Connection

## NOTES

Connections belong to one runspace and are never persisted as profiles.

## RELATED LINKS

[Shared authentication](https://atlassianps.org/docs/AtlassianPS.Configuration/about/authentication.html)

[Jira authentication](https://atlassianps.org/docs/JiraPS/about/authentication.html)
