---
applyTo: "**/*.ps1"
---

# Jira Cloud vs Data Center Compatibility

JiraPS targets both Jira Cloud and Jira Data Center. These are different
products with different API behaviors. Any change to API endpoints, request
bodies, or response handling MUST work on both deployment types.

## User Identity (Critical)

- Cloud uses `accountId` (GDPR removed `username`/`name`)
- Data Center uses `username` / `name`
- If a function uses `?username=` or `@{name=...}`, it only works on DC
- If a function uses `?accountId=` or `@{accountId=...}`, it only works on Cloud
- Correct approach: branch based on deployment type

Affected: `Get-JiraUser`, `Set-JiraUser`, `Remove-JiraUser`, `New-JiraIssue`
(reporter), `Set-JiraIssue` (assignee), `Invoke-JiraIssueTransition`,
`Add-JiraGroupMember`, `Remove-JiraGroupMember`, `Add-JiraIssueWatcher`,
`Remove-JiraIssueWatcher`, `Resolve-JiraUser`

## Text Fields (ADF vs Plain Text)

- Cloud v3: description, comment body, and similar fields use Atlassian
  Document Format (ADF) — a JSON structure with `type: "doc"`
- Data Center: these fields are plain strings or wiki markup
- Sending ADF to DC produces garbled content or API errors
- Reading DC plain strings through ADF conversion is wasteful
- `ConvertTo-AtlassianDocumentFormat` (alias `ConvertTo-ADF`) must only be used for Cloud
- `ConvertFrom-AtlassianDocumentFormat` (alias `ConvertFrom-ADF`) must only be used for Cloud
  (though the function gracefully handles strings as a fallback)
- Both functions are public so users can convert ADF manually when using
  `Invoke-JiraMethod` against Cloud v3 endpoints — JiraPS's built-in
  read/write commands don't cover every API surface

## Search Endpoint

- Cloud: `POST /rest/api/3/search/jql` (JSON body, token pagination)
- Data Center: `GET /rest/api/2/search` (query params, offset pagination)
- These are NOT interchangeable — the Cloud endpoint may not exist on DC
- `nextPageToken` pagination is Cloud-only; DC uses `startAt`/`maxResults`

## API Version

- Do NOT blindly swap `/rest/api/2/` to `/rest/api/3/` across all endpoints
- Cloud is migrating to v3; Data Center retains full v2 support
- v3 availability on DC varies by release version
- Endpoint version changes must be deployment-aware

## Deployment Detection

- `Get-JiraServerInformation` returns `deploymentType` (`Cloud` or `Server`)
- This value is mapped in `ConvertTo-JiraServerInfo` but NOT used for branching
- Any Cloud/DC-aware logic should use this value to select behavior

## Review Checklist

When reviewing changes to API endpoints or REST call handling:

1. Does the change work on BOTH Cloud and Data Center?
2. If user identity is involved: is `accountId` used for Cloud and
   `username`/`name` for DC?
3. If text fields are read/written: is ADF conversion conditional on
   deployment type?
4. If search is changed: does it handle both POST/token (Cloud) and
   GET/offset (DC) patterns?
5. If URL version is changed to v3: are query params and body fields
   also updated to match v3 semantics?
6. Does the PR claim backward compatibility? Is that claim accurate
   for BOTH deployment types?
7. Do tests cover both Cloud and DC response shapes?
