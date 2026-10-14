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

Validate and open a named Jira connection.

## EXAMPLES

### EXAMPLE 1

```powershell
$work = Connect-Jira -Name work -Uri 'https://work.atlassian.net' -EmailAddress 'me@example.com' -ApiToken $env:JIRA_API_TOKEN
```

Use the normal Cloud site URL. Discovery identifies the site and resolves the API gateway.

### EXAMPLE 2

```powershell
$internal = Connect-Jira -Name internal -Uri 'https://jira.example.com/jira' -PersonalAccessToken (Read-Host 'Jira PAT' -AsSecureString)
```

Open a Data Center connection using a masked PAT input.

### EXAMPLE 3

```powershell
$work = Connect-Jira -Name work -Profile work -EmailAddress 'me@example.com' -ApiToken (Get-Secret JiraToken)
```

Compose a saved non-secret profile with an already-installed secret vault. The vault module is optional.

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

Standalone Jira product endpoint for this logical operation. Cannot be combined with Connection or ConnectionName. Supply one explicit authentication mode; use Anonymous for anonymous access. Normal HTTPS commercial Atlassian site URLs resolve cloudId and the API gateway automatically for ApiToken authentication.

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

Saved Jira server profile. Only approved non-secret endpoint settings are copied; saved Session values are ignored. Supply authentication explicitly.

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

### -Default

Select the successful new connection as Jira default, or filter the listing to the current default. The first successful connection selects itself automatically; later connections leave an existing default unchanged unless this switch is supplied.

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

### AtlassianPS.Connection

## OUTPUTS

### AtlassianPS.Connection

## NOTES

Connections belong to one runspace and are never persisted as profiles.

## RELATED LINKS

[Shared authentication](https://atlassianps.org/docs/AtlassianPS.Configuration/about/authentication.html)

[Jira authentication](https://atlassianps.org/docs/JiraPS/about/authentication.html)
