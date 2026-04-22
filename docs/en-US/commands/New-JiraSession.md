---
document type: cmdlet
external help file: JiraPS-help.xml
HelpUri: https://atlassianps.org/docs/JiraPS/commands/New-JiraSession/
Locale: en-DE
Module Name: JiraPS
ms.date: 04.22.2026
PlatyPS schema version: 2024-05-01
title: New-JiraSession
---

# New-JiraSession

## SYNOPSIS

Creates a persistent JIRA authenticated session which can be used by other JiraPS functions

## SYNTAX

### Credential (Default)

```
New-JiraSession [-Credential <pscredential>] [-Headers <hashtable>] [<CommonParameters>]
```

### PersonalAccessToken

```
New-JiraSession -PersonalAccessToken <securestring> [-Headers <hashtable>] [<CommonParameters>]
```

### ApiToken

```
New-JiraSession -ApiToken <securestring> -EmailAddress <string> [-Headers <hashtable>]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

This function creates a persistent, authenticated session in to JIRA which can be used by all other JiraPS functions instead of explicitly passing parameters.

This removes the need to use the `-Credential` parameter constantly for each function call.

JiraPS supports multiple authentication methods:

- **Credential**: Traditional username/password authentication (Jira Data Center) - **PersonalAccessToken**: Personal Access Token (PAT) authentication (Jira Data Center 8.14+) - **ApiToken**: API Token authentication with email address (Jira Cloud)

You can find more information in [about_JiraPS_Authentication](../../about/authentication.html)

## EXAMPLES

### EXAMPLE 1

New-JiraSession -Credential (Get-Credential jiraUsername)
Get-JiraIssue TEST-01


Creates a Jira session for jiraUsername using basic authentication.
The following `Get-JiraIssue` is run using the saved session for jiraUsername.

### EXAMPLE 2

$pat = Read-Host -AsSecureString "Enter your PAT"
New-JiraSession -PersonalAccessToken $pat
Get-JiraIssue TEST-01


Creates a Jira session using a Personal Access Token (PAT) with Bearer authentication.
This is the recommended method for Jira Data Center 8.14 and later.

### EXAMPLE 3

$apiToken = Read-Host -AsSecureString "Enter your API token"
New-JiraSession -ApiToken $apiToken -EmailAddress "user@example.com"
Get-JiraIssue TEST-01


Creates a Jira session using an API token with your Atlassian account email.
This is the recommended method for Jira Cloud.

### EXAMPLE 4

$headers = @{ "X-Custom-Header" = "value" }
New-JiraSession -PersonalAccessToken $pat -Headers $headers


Creates a Jira session with a PAT and additional custom headers.

### EXAMPLE 5

$pat = ConvertTo-SecureString $env:JIRA_PAT -AsPlainText -Force
New-JiraSession -PAT $pat


Uses the `-PAT` alias for brevity.
The `-BearerToken` alias is also supported for backward compatibility.

## PARAMETERS

### -ApiToken

An API token for Jira Cloud authentication.
Must be used together with `-EmailAddress`.

Create an API token at: https://id.atlassian.com/manage-profile/security/api-tokens

```yaml
Type: System.Security.SecureString
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ApiToken
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Credential

Credentials to use to connect to JIRA using basic authentication.

```yaml
Type: System.Management.Automation.PSCredential
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Credential
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -EmailAddress

The email address associated with your Atlassian account.
Required when using `-ApiToken` for Jira Cloud authentication.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ApiToken
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Headers

Additional headers to include in requests.

```yaml
Type: System.Collections.Hashtable
DefaultValue: '@{}'
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

### -PersonalAccessToken

A Personal Access Token (PAT) for Bearer token authentication.
Use this for Jira Data Center 8.14 and later.

Create a PAT in Jira: Profile > Personal Access Tokens > Create token

Aliases: `BearerToken`, `PAT`

```yaml
Type: System.Security.SecureString
DefaultValue: ''
SupportsWildcards: false
Aliases:
- BearerToken
- PAT
ParameterSets:
- Name: PersonalAccessToken
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
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

### PSCredential

{{ Fill in the Description }}

## OUTPUTS

### JiraPS.Session

{{ Fill in the Description }}

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.


## RELATED LINKS

- [Online Version](https://atlassianps.org/docs/JiraPS/commands/New-JiraSession/)
- [about_JiraPS_Authentication](../../about/authentication.html)
- [Get-JiraSession](../Get-JiraSession/)
