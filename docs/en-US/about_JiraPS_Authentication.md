---
locale: en-US
layout: documentation
title: Authentication
online version: https://atlassianps.org/docs/JiraPS/about/authentication.html
Module Name: JiraPS
permalink: /docs/JiraPS/about/authentication.html
---
# Authentication

## about_JiraPS_Authentication

# SHORT DESCRIPTION

Connect to Jira, choose an identity and migrate v2 session scripts.

# LONG DESCRIPTION

JiraPS uses AtlassianPS.Configuration for named live connections.
The shared [authentication guide](https://atlassianps.org/docs/AtlassianPS.Configuration/about/authentication.html) owns token handling, defaults, overrides and non-secret profiles.
This Jira candidate is experimental.

## Quick start

```powershell
$work = Connect-Jira -Name work -Uri 'https://work.atlassian.net' -EmailAddress 'me@example.com' -ApiToken $env:JIRA_API_TOKEN
Get-JiraIssue -Key PROJ-1
$admin = Connect-Jira -Name admin -Uri 'https://work.atlassian.net' -EmailAddress 'admin@example.com' -ApiToken (Read-Host 'Admin Jira token' -AsSecureString)
Get-JiraIssue -Key PROJ-1 -Connection $admin
Get-JiraIssue -Key PROJ-1 -Connection (Get-JiraConnection -Name work)
$admin | Select-JiraConnection
$admin | Disconnect-Jira
```

The first successful connection becomes the Jira default.
Opening admin leaves work selected unless Default is requested.
An explicit per-call connection does not change the default.
Removing the default clears it without selecting another connection.

Ordinary Jira commands accept an optional Connection object.
Use Connect-Jira to set the endpoint and authentication.
Use Get-JiraConnection -Name to resolve a connection by name.

## Deployment support

| Deployment | Inputs | Request authentication |
| --- | --- | --- |
| Jira Cloud | EmailAddress plus ApiToken, either string or SecureString | Basic email/token, with automatic site discovery and API endpoint resolution |
| Jira Cloud compatibility | PSCredential containing email and API token | Basic at the selected endpoint; use explicit ApiToken inputs for automatic scoped-token routing |
| Jira Data Center | PersonalAccessToken, either string or SecureString | Bearer without a username |
| Jira Data Center | PSCredential containing username/password | Basic |
| Permitted anonymous endpoints | Anonymous | Fresh anonymous context |

Use HTTPS for production endpoints.
Explicit HTTP endpoints remain available for local Data Center test environments.
No browser OAuth, SSO, automatic refresh or cookie-login requirement is added.

## Deployment discovery on restricted installations

Connect-Jira prefers a recognized deploymentType from serverInfo without requiring a version.
If metadata is absent or restricted with HTTP 403, 404 or 405, a successful myself response identifies Cloud through accountId or Server/Data Center through name.
A resolved Cloud gateway also provides Cloud evidence.
When connecting directly to a gateway, site resource links require a valid baseUrl from serverInfo; relative resources remain available when that metadata is absent.
Conflicting evidence or a response containing both identity formats fails.
Authentication, network, TLS and server failures remain errors.

Deployment detection is automatic; Server and Data Center use the same API family.
Every authenticated connection validates the current user through myself, including when serverInfo supplies deployment metadata.

Anonymous connections require recognized deployment metadata from /rest/api/2/serverInfo.
If that endpoint is restricted or does not identify the deployment, allow anonymous access to it or use an authenticated connection.

## Authentication examples

Choose the authentication method supported by your Jira deployment.
Each example creates a connection and uses it for a Jira operation.

### Jira Cloud API token

```powershell
$token = Read-Host 'Jira API token' -AsSecureString
$cloud = Connect-Jira -Name cloud -Uri 'https://work.atlassian.net' -EmailAddress 'me@example.com' -ApiToken $token
Get-JiraIssue -Key PROJ-1 -Connection $cloud
```

Supply the normal Cloud site URL and your authentication email.
Connect-Jira discovers the API gateway and validates the supplied identity before returning the connection.

### Data Center personal access token

```powershell
$token = Read-Host 'Jira PAT' -AsSecureString
$internal = Connect-Jira -Name internal -Uri 'https://jira.example.com/jira' -PersonalAccessToken $token
Get-JiraProject -Connection $internal
```

Use the Data Center endpoint, including its context path when Jira is hosted below /jira.
A PAT authenticates without a username.

### Username and password

```powershell
$credential = Get-Credential
$basic = Connect-Jira -Name basic -Uri 'https://jira.example.com/jira' -Credential $credential
Get-JiraIssue -Key PROJ-1 -Connection $basic
```

Supply a Data Center username and password through the credential prompt.
For Jira Cloud credential compatibility, the credential contains an email and API token; use EmailAddress with ApiToken for automatic site discovery and scoped-token routing.

### Anonymous access

```powershell
$public = Connect-Jira -Name public -Uri 'https://jira.example.com' -Anonymous
Get-JiraProject -Connection $public
```

The endpoint and requested operation must permit anonymous access.
Anonymous is explicit and never borrows an existing connection's identity.
Ordinary Jira commands use their selected connection.
Create an anonymous connection explicitly when the endpoint permits it.

### Saved endpoint profiles

```powershell
Add-AtlassianServerConfiguration -Name work -Type Jira -Uri 'https://work.atlassian.net'
$token = Read-Host 'Jira API token' -AsSecureString
$profile = Connect-Jira -Name profile -Profile work -EmailAddress 'me@example.com' -ApiToken $token
Get-JiraIssue -Key PROJ-1 -Connection $profile
```

The saved profile can be reused in another PowerShell session.
It stores endpoint settings; supply authentication each time you create a live connection.
Profile names and live connection names are independent.

## Cloud site and API endpoints

Supply your normal HTTPS commercial Atlassian site URL.
For ApiToken authentication, JiraPS reads /_edge/tenant_info without authentication, validates cloudId and builds the fixed api.atlassian.com Jira gateway route.
Discovery does not prove the supplied identity; Connect also validates Jira metadata and the authenticated myself endpoint.
Failed discovery does not select Data Center or change an existing default.

| Context value | Meaning |
| --- | --- |
| SiteUri | The user's browser site URL |
| CloudId | Non-secret identifier returned by site discovery |
| BaseUri | Frozen API route, such as https://api.atlassian.com/ex/jira/cloudId |

The gateway prefix survives leading-slash resources, nested lookups, retries and pagination.
Matching site REST URLs returned by Jira are translated to the selected gateway.
Another cloudId, another product path, unexpected origin or encoded path escape is rejected before authentication is attached.

Explicit gateway endpoints are an advanced alternative when site discovery is unavailable.
Custom domains and other Atlassian environments require separately validated support; JiraPS does not guess their gateway.

Atlassian's [API-token guide](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/) documents gateway routing for scoped tokens.
No token kind is inferred from its length or prefix, and domain operations do not retry against another authentication endpoint.

## Permissions and scopes

Creation-time identity validation needs permission to access Jira and the scopes documented for [Get current user](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-myself/#api-rest-api-3-myself-get).
Its classic scope is read:jira-user; granular alternatives include read:application-role:jira, read:group:jira, read:user:jira and read:avatar:jira.
Issue retrieval needs the scopes of [Get issue](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/#api-rest-api-3-issue-issueidorkey-get), in addition to project and issue permissions.
A successful Connect does not establish access to every operation.
For a read-only scoped API token that validates identity and reads issues, the complete classic scope list is `read:jira-user` and `read:jira-work`.
A 401 with "scope does not match" or a 403 can indicate missing scopes; check the requested operation before replacing otherwise valid credentials.

## Connection selection

```powershell
$work = Get-JiraConnection -Name work
Get-JiraIssue -Issue PROJ-1 -Connection $work
Select-JiraConnection -Connection $work
Get-JiraIssue -Issue PROJ-2
```

Connection chooses an active Jira connection for an operation.
Omitting Connection uses the selected Jira default.
Nested lookups, retries and subsequent pages reuse that same resolved context.
Authentication is supplied when creating the connection; per-call Credential and the Session alias are removed.
For a different identity or endpoint, create another connection with Connect-Jira and pass it to the command.
New-JiraUser and Set-JiraUser use EmailAddress only for the user field.

## Low-level standalone requests

Invoke-JiraMethod also supports an explicit endpoint and authentication for direct REST requests.
Supply BaseUri and exactly one authentication method in the same call.
Authentication inputs cannot be combined with Connection or ConnectionName.
Standalone requests validate the authenticated myself endpoint and dispose their temporary connection without changing the default.

```powershell
Invoke-JiraMethod -BaseUri 'https://jira.example.com/jira' -Uri '/rest/api/2/myself' -PersonalAccessToken $env:JIRA_PAT
```

These standalone requests validate one context without registering a connection or changing the Jira default.
Uri is the REST resource and BaseUri is the Jira product endpoint.
Token inputs, ConnectionName and standalone endpoints belong on Connect-Jira or Invoke-JiraMethod, rather than ordinary Jira commands.

## Migration from JiraPS v2

| Removed interface | Replacement |
| --- | --- |
| New-JiraSession | Connect-Jira with an explicit endpoint or saved profile |
| Get-JiraSession | Get-JiraConnection; use Default for the selected Jira connection |
| Set-JiraSession | Select-JiraConnection |
| Remove-JiraSession | Disconnect-Jira |
| Session parameter | Connection |
| Get-JiraConfigServer | Get-JiraConnection endpoint properties or an explicit shared profile |
| Set-JiraConfigServer | Add/Set-AtlassianServerConfiguration for a named endpoint profile |
| Credential-only request or per-call credential override | Create a connection with authentication and pass Connection |
| AtlassianPS.JiraPS.Session | AtlassianPS.Connection |
| Invoke-JiraMethod StoreSession | Connect-Jira |

No command imports the installed module's legacy server_config automatically.
Saved profiles and live connections remain independent.
JiraAgilePS's existing package still pins JiraPS 2.16.0 and has not adopted this v3 contract.
Use separate processes for existing Agile/v2 workflows and the v3 candidate.

## Pipeline cancellation

Temporary request contexts are disposed after normal completion and errors inside the command.
The commands use lifecycle blocks compatible with Windows PowerShell 5.1, which has no script-function cleanup block for upstream pipeline failures or cancellation.
In that case, unreferenced secure secret copies are reclaimed by .NET; removing AtlassianPS.Configuration also disposes any retained temporary contexts.
Cancellation therefore does not guarantee immediate disposal.

# SEE ALSO

[about_AtlassianPS_Authentication](https://atlassianps.org/docs/AtlassianPS.Configuration/about/authentication.html)

[Connect-Jira](https://atlassianps.org/docs/JiraPS/commands/Connect-Jira/)
