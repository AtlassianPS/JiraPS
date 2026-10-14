---
Module Name: JiraPS
locale: en-US
layout: documentation
permalink: /docs/JiraPS/about/authentication.html
---
# about_JiraPS_Authentication

## SHORT DESCRIPTION

Connect to Jira, choose an identity and migrate v2 session scripts.

## LONG DESCRIPTION

JiraPS uses AtlassianPS.Configuration for named live connections.
The shared [authentication guide](https://atlassianps.org/docs/AtlassianPS.Configuration/about/authentication.html) owns token handling, defaults, overrides and non-secret profiles.
This Jira candidate is experimental.
Final scoped/unscoped Cloud, Data Center and Windows PowerShell acceptance remains subject to the candidate's recorded integration results.

### Quick start

```powershell
$work = Connect-Jira -Name work -Uri 'https://work.atlassian.net' -EmailAddress 'me@example.com' -ApiToken $env:JIRA_API_TOKEN
Get-JiraIssue -Key PROJ-1
$admin = Connect-Jira -Name admin -Uri 'https://work.atlassian.net' -EmailAddress 'admin@example.com' -ApiToken (Read-Host 'Admin Jira token' -AsSecureString)
Get-JiraIssue -Key PROJ-1 -Connection $admin
Get-JiraIssue -Key PROJ-1 -ConnectionName work
$admin | Select-JiraConnection
$admin | Disconnect-Jira
```

The first successful connection becomes the Jira default.
Opening admin leaves work selected unless Default is requested.
An explicit per-call connection or authentication override does not change the default.
Removing the default clears it without selecting another connection.

### Deployment support

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

### Cloud site and API endpoints

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
A new identity override keeps the selected connection's API endpoint.
If it cannot authenticate there, create a new connection with the normal site URL.

Explicit gateway endpoints are an advanced alternative when site discovery is unavailable.
Custom domains and other Atlassian environments require separately validated support; JiraPS does not guess their gateway.

Atlassian's [API-token guide](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/) documents gateway routing for scoped tokens.
The candidate ledger records the configured-token gateway experiment and any missing token coverage.
No token kind is inferred from its length or prefix, and domain operations do not retry against another authentication endpoint.

### Permissions and scopes

Creation-time identity validation needs permission to access Jira and the scopes documented for [Get current user](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-myself/#api-rest-api-3-myself-get).
Its classic scope is read:jira-user; granular alternatives include read:application-role:jira, read:group:jira, read:user:jira and read:avatar:jira.
Issue retrieval needs the scopes of [Get issue](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issues/#api-rest-api-3-issue-issueidorkey-get), in addition to project and issue permissions.
A successful Connect does not establish access to every operation.
A 403 can indicate missing scopes or ordinary Jira permissions; it does not always mean a bad token.

### Standalone requests and overrides

```powershell
Get-JiraIssue -Key PROJ-1 -Uri 'https://work.atlassian.net' -EmailAddress 'me@example.com' -ApiToken $env:JIRA_API_TOKEN
Invoke-JiraMethod -BaseUri 'https://jira.example.com/jira' -Uri '/rest/api/2/myself' -PersonalAccessToken $env:JIRA_PAT
Get-JiraIssue -Key PROJ-1 -Connection $work -Credential $oneOffCredential
```

Standalone calls validate one context for the logical operation without registering or selecting it.
Nested lookups and subsequent pages reuse that same context.
Explicit empty authentication fails instead of falling back to the stored identity.
Each API-token override includes its own authentication email and token.
New-JiraUser and Set-JiraUser retain EmailAddress for the user field and use AuthenticationEmailAddress for a token override.
Other request commands use EmailAddress, with Email as an alias.

### Migration from JiraPS v2

| Existing interface | Current behavior |
| --- | --- |
| New-JiraSession | Thin Connect adapter; omitted name gets a unique generated name; omitted endpoint uses the current default then configured migration endpoint |
| Get-JiraSession | Lists shared AtlassianPS.Connection objects, including multiple connections |
| Set-JiraSession | Compatibility selection entry point |
| Remove-JiraSession | Thin Disconnect adapter; no selector removes only the Jira default |
| Session parameter | Alias for Connection |
| Server/ServerName request selectors | Aliases for ConnectionName; never interpreted as URLs |
| AtlassianPS.JiraPS.Session | Replaced by the shared AtlassianPS.Connection type |
| Set-JiraConfigServer | Obsolete non-secret endpoint/profile adapter; persists through shared configuration rather than the installed module |
| Credential-only request | Uses the live default, then a configured migration endpoint when no default exists |
| Invoke-JiraMethod StoreSession | Obsolete; use Connect-Jira |
| Injected Authorization/Cookie headers or low-level authentication defaults | Rejected; use Credential, ApiToken or PersonalAccessToken |

Repeated New-JiraSession calls do not replace an existing default unless Default is supplied.
Legacy server_config is read as a migration input without rewriting it.
Saved profiles and live connections remain independent.
JiraAgilePS's existing package still pins JiraPS 2.16.0 and has not adopted this v3 contract.
Use separate processes for existing Agile/v2 workflows and the v3 candidate.

## SEE ALSO

[about_AtlassianPS_Authentication](https://atlassianps.org/docs/AtlassianPS.Configuration/about/authentication.html)

[Connect-Jira](https://atlassianps.org/docs/JiraPS/commands/Connect-Jira/)

## Pipeline cancellation

Temporary request contexts are disposed after normal completion and errors inside the command.
The commands use lifecycle blocks compatible with Windows PowerShell 5.1, which has no script-function cleanup block for upstream pipeline failures or cancellation.
In that case, unreferenced secure secret copies are reclaimed by .NET; removing AtlassianPS.Configuration also disposes any retained temporary contexts.
Cancellation therefore does not guarantee immediate disposal.
