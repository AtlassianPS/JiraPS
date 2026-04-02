<!-- Generated: March 2026 — Cloud vs Data Center implementation audit -->
<!-- Updated: March 2026 — Post-implementation status -->
<!-- This analysis documents known gaps in JiraPS's handling of Jira Cloud vs Data Center API differences. -->
<!-- Use this as a reference when planning compatibility improvements. -->

# Cloud vs Data Center: Implementation Gap Analysis

This document captures the results of auditing JiraPS source code against the
documented API differences in [cloud-vs-datacenter.md](cloud-vs-datacenter.md).

> **Status (March 2026)**: All critical and moderate gaps have been resolved
> in the `cloud-compat` branch. See the [CHANGELOG](../../../../CHANGELOG.md)
> `Unreleased` section for a summary of all changes.

---

## Critical: User Identification is DC-Centric — RESOLVED

The module overwhelmingly uses `name`/`username` (Data Center pattern) for user
identification in API calls. Jira Cloud uses `accountId` and has **removed**
`name`/`key` under GDPR.

### Affected Functions

| Function | Status | Resolution |
|----------|--------|------------|
| `Get-JiraUser` | **Fixed** | Added `-AccountId` parameter set; uses `?query=` for search and `?accountId=` for exact lookup on Cloud |
| `Set-JiraUser` | **Fixed** | Uses `?accountId=` on Cloud |
| `Remove-JiraUser` | **Fixed** | Uses `?accountId=` on Cloud |
| `New-JiraIssue` | **Fixed** | Reporter uses `@{ accountId = ... }` on Cloud |
| `Set-JiraIssue` | **Fixed** | Assignee uses `@{ accountId = ... }` on Cloud |
| `Invoke-JiraIssueTransition` | **Fixed** | Assignee uses `@{ accountId = ... }` on Cloud |
| `Add-JiraGroupMember` | **Fixed** | POST body uses `@{ accountId = ... }` on Cloud |
| `Remove-JiraGroupMember` | **Fixed** | Uses `&accountId=` query parameter on Cloud |
| `Remove-JiraIssueWatcher` | **Fixed** | Uses `?accountId=` on Cloud |
| `Add-JiraIssueWatcher` | **Fixed** | POST body sends `accountId` string on Cloud |

### `ConvertTo-JiraUser.ToString()` Returns Empty on Cloud — RESOLVED

`ToString()` now falls back to `DisplayName`, then `AccountId` when `Name` is
empty (GDPR compliance).

### `Resolve-JiraUser` Has No `accountId` Path — RESOLVED

`Resolve-JiraUser` now detects Cloud deployment type and routes strings matching
the `accountId` pattern (`[0-9a-f]{24}`) through `Get-JiraUser -AccountId`.

## Moderate: User Search Parameters — RESOLVED

`Get-JiraUser` now branches by deployment type:
- **Cloud**: `/user/search?query=<text>` and `/user?accountId=<id>`
- **DC**: `/user/search?username=<text>` and `/user?username=<name>`

### `Get-JiraUser -Self` Re-fetches Using `Name` — RESOLVED

`-Self` now re-fetches using `Get-JiraUser -AccountId` on Cloud and
`Get-JiraUser -UserName` on Data Center.

## Moderate: Watchers Not Normalized — RESOLVED

`Get-JiraIssueWatcher` now pipes watchers through `ConvertTo-JiraUser`,
producing consistent `JiraPS.User` typed output on both platforms.

## Moderate: `Find-JiraFilter` is Cloud-Oriented (Opposite Problem) — OPEN

```powershell
# JiraPS/Public/Find-JiraFilter.ps1 (lines 97-102)
if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('AccountId')) {
    $parameter['GetParameter']['accountId'] = $AccountId
}
```

This function pushes `accountId` into filter search, which may not work on Data
Center if that API expects different owner identification.

> **Note**: This was not addressed in the current work as it requires
> investigation into the Data Center filter search API.

## Lower Severity

### No Cloud Session Deprecation Warning — RESOLVED

`New-JiraSession` now emits a `Write-Warning` when the configured server is
detected as Jira Cloud.

### No Rate Limit / 429 Handling — RESOLVED

`Invoke-JiraMethod` now handles HTTP 429 responses with automatic retry.
Respects the `Retry-After` header when present; falls back to exponential
backoff (1s, 2s, 4s) with a maximum of 3 retries.

### No Deployment Type Awareness — RESOLVED

`Get-JiraServerInformation` now caches its result in `$script:JiraServerInfo`.
All functions that need Cloud/DC branching call
`(Get-JiraServerInformation).DeploymentType`. The cache is:
- Cleared when `Set-JiraConfigServer` is called (new server URL)
- Bypassable with `Get-JiraServerInformation -Force`
- Defaults to `'Server'` when the API doesn't return `deploymentType` (old Jira
  Server versions) or when the API call fails

### Create Metadata Test Mismatch — OPEN

`Get-JiraIssueCreateMetadata` correctly uses the new path-based endpoint
(`/createmeta/{projectId}/issuetypes/{issueTypeId}`), but its test file still
mocks the old `?`-style endpoint and expects the legacy response shape.

### Pagination — RESOLVED

Pagination has been extracted into a dedicated `Invoke-PaginatedRequest`
private function that supports both:
- **Offset-based** (`startAt`/`maxResults`) for API v2 (Data Center)
- **Token-based** (`nextPageToken`) for API v3 (Cloud)

`Get-JiraIssue` JQL search uses `/rest/api/3/search/jql` on Cloud with
token-based pagination.

## What's Working Well

- **`ConvertTo-JiraUser`** maps all fields from both platforms (`accountId`,
  `name`, `key`, `emailAddress`, etc.) — stores whatever the API returns.
- **`ConvertTo-JiraIssue`** delegates user fields (reporter, assignee, creator)
  through `ConvertTo-JiraUser`.
- **`ConvertTo-JiraComment`** and **`ConvertTo-JiraWorklogitem`** handle
  `author`/`updateAuthor` through `ConvertTo-JiraUser`.
- **Pagination** in `Invoke-PaginatedRequest` respects the server's returned
  `maxResults`, adapting at runtime even if the server caps the page size.
  Supports both v2 offset-based and v3 token-based pagination.
- **`Get-JiraIssueCreateMetadata`** uses the modern path-based endpoint, aligned
  with Cloud's direction.
- **Authentication** works for both platforms via `PSCredential` (email+token on
  Cloud, username+password on DC).
- **Deployment detection** is automatic, cached, and transparent to callers.

## Fix Strategy — Implementation Status

| # | Strategy | Status |
|---|----------|--------|
| 1 | **Detect deployment type** — Cache `deploymentType` from `Get-JiraServerInformation` | **Done** |
| 2 | **Branch user identification** — Use `accountId` on Cloud, `name`/`username` on DC | **Done** |
| 3 | **Fix `ToString()`** — Fall back to `DisplayName` or `AccountId` | **Done** |
| 4 | **Normalize watchers** — Pass through `ConvertTo-JiraUser` | **Done** |
| 5 | **Add rate limit retry** — Handle 429 with exponential backoff | **Done** |
| 6 | **Warn on session auth for Cloud** — Warning in `New-JiraSession` | **Done** |

### Additional work completed beyond original strategy

- **Token-based pagination** — `Invoke-PaginatedRequest` supports API v3's
  `nextPageToken` pagination (ported from `patch-1` branch with bug fixes)
- **Cloud JQL endpoint** — `Get-JiraIssue` uses `/rest/api/3/search/jql` on
  Cloud
- **Comprehensive test coverage** — Cloud deployment test contexts added to 11
  test files
- **Documentation** — Updated help docs for `Get-JiraServerInformation`,
  `Get-JiraUser`, and authentication guide
