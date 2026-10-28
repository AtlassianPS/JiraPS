# Change Log

## Unreleased

### Breaking changes

- Minimum supported PowerShell version is now 5.1.
- Session commands use shared `AtlassianPS.Connection` objects instead of `AtlassianPS.JiraPS.Session`.
  `Get-JiraSession` lists connections; use `-Default` to retrieve the selected Jira connection.
- `-Credential` no longer defaults to `PSCredential::Empty`; omitting it uses the selected connection.
  Explicit null or empty credentials fail instead of falling back to another identity.
  Use `Connect-Jira -Anonymous` for anonymous access.
- Authentication through `New-JiraSession -Headers`, Authorization/Cookie headers, or low-level web request authentication defaults is rejected.
  Configure authentication with `Connect-Jira`; ordinary Jira commands retain `-Credential` for per-call overrides.
- `Invoke-JiraMethod -StoreSession` no longer creates a session; use `Connect-Jira` to create a reusable connection.
- Domain objects use `AtlassianPS.JiraPS.<Type>` instead of the historic `JiraPS.<Type>` PSTypeNames.
  Update type checks and mocks to the new namespace; prefer `$obj -is [AtlassianPS.JiraPS.Issue]` for type checks.
- Issue, user, group, project, version, filter, and issue-link parameters use strongly typed objects with argument transformation.
  Identifier and name shorthand remain supported where documented, while invalid or empty inputs fail at parameter binding.
  Parameters declared as a single object accept multiple objects through the pipeline; only array parameters accept arrays directly.
- Known URL properties use `[Uri]`, and issue, comment, worklog, and server timestamps use nullable `[DateTimeOffset]` values.
  Cast explicitly when scripts require strings, and check for `$null` when optional values are absent.
- `Issue.Assignee` is a `User` or `$null` for an unassigned issue.
  `Issue.Status` is a `Status` object; compare `$issue.Status.Name` with a status name.
- Properties with a fixed set of values use nullable enums; unknown API values become `$null`.
- `Filter.Favourite`, `Version.Archived`, `Version.Released`, and `Version.Overdue` are booleans with `$false` for omitted flags.
  `Version.Project` is a nullable integer ID, and `Version.StartDate` / `ReleaseDate` are nullable dates instead of empty strings.
- Removed deprecated `-StartIndex` and `-MaxResults` parameters from `Get-JiraIssue` and `Get-JiraGroupMember`.
  Use `-Skip` and `-First` instead.
- `Set-JiraIssue -Assignee` no longer accepts `'Unassigned'`, `'Default'`, `$null`, or empty strings.
  Use `-Unassign` or `-UseDefaultAssignee` instead.
  `Invoke-JiraIssueTransition -Assignee` likewise requires `-Unassign` to remove an assignee.
  Assignee switches and explicit user input are mutually exclusive.
- `New-JiraIssue -Reporter` rejects `$null` and empty strings; omit the parameter to use Jira's default reporter.
- `Add-JiraIssueLink -IssueLink` accepts `IssueLinkCreateRequest[]`, with both `inwardIssue` and `outwardIssue` references required in every request.
  The `-Issue` anchor parameter was removed.

See [`about_JiraPS_MigrationV3`](https://atlassianps.org/docs/JiraPS/about/migration-v3.html) for before/after examples and detailed input contracts.
See the [authentication guide](docs/en-US/about_JiraPS_Authentication.md) for connection and session migration examples.

### Added

- `Connect-Jira`, `Get-JiraConnection`, `Select-JiraConnection`, and `Disconnect-Jira` manage named connections for multiple Jira sites and identities.
  Pass `-Connection` (alias `-Session`) to target one command; omitting it uses the selected Jira default.
- `Connect-Jira` and compatibility `New-JiraSession` support Cloud API tokens through `-ApiToken` and `-EmailAddress`, and Data Center personal access tokens through `-PersonalAccessToken` (aliases `-PAT`, `-BearerToken`).
  Token parameters accept strings and `SecureString` values. (#576)
  Cloud API tokens, including scoped tokens, work with the normal site URL through automatic API endpoint discovery.
- `Get-JiraStatus` retrieves statuses by ID or name, or lists all statuses.
- `Get-JiraIssue -IncludeHistory` returns issue history entries, with `-GetHistory` retained as an alias.
- `Invoke-JiraIssueTransition -TimeSpent` records a worklog entry as part of an issue transition. (#343, [@alexsuslin])
- `Set-JiraIssue` and `Invoke-JiraIssueTransition` support `-Unassign` to remove an assignee.
  `Set-JiraIssue -UseDefaultAssignee` assigns the project's default assignee on Cloud and Data Center.
- `New-JiraIssue` supports mutually exclusive `-Assignee` and `-Unassign` parameters.
  `-Assignee` accepts a username, Cloud account ID, or typed `User`; omitting both parameters lets Jira apply the project default.
- `New-JiraIssueLinkRequest` builds typed link requests from `-Type`, `-FromIssue`, and `-ToIssue`.
- `ConvertTo-JiraTable` returns Jira wiki-markup table text.
  `Format-Jira` remains a deprecated exported alias.
- `Invoke-JiraMethod` supports `-TimeoutSec` (default `100`; `0` disables the timeout), plus `-CacheKey`, `-CacheExpiry`, and `-BypassCache` for response caching. (#576)
- `Get-JiraField`, `Get-JiraIssueType`, `Get-JiraPriority`, and `Get-JiraServerInformation` cache responses and support `-Force` to refresh them.
  `Clear-JiraCache` clears cached responses by type. (#576)
- `Set-JiraResponseHeaderLogConfiguration` enables debug logging for selected Jira response headers, and `Get-JiraResponseHeaderLogConfiguration` reports the active configuration. (#536)
- Identifier-based constructors and hashtable initialization are supported for `Issue`, `User`, `Project`, `Group`, `Filter`, and `Version` objects.
  These types support equality, hashing, and sorting by their canonical identifiers; objects without identifiers remain distinct.
- Returned objects expose additional user account details, project flags and contact information, rendered comment bodies and entity properties, and server version, display URL, time-zone, and locale information.
- Added authentication examples for automation and CI/CD, a contributor object-model reference, and migration examples for typed inputs and outputs.

### Changed

- JiraPS uses AtlassianPS.Configuration for connection state, authentication and saved endpoint settings.
- `New-JiraSession` preserves an existing default unless `-Default` is supplied.
  Session commands and connection commands manage the same connections.
- `Set-JiraConfigServer` saves endpoint settings through shared configuration.
  Existing `server_config` files remain readable as migration inputs and are no longer rewritten.
- Debug messages follow Configuration's message settings, including breadcrumbs, and redact authentication values.
- Core objects, leaf objects, issue history, remote links, visibility, role actors, schemas, filter subscriptions, and standard issue fields return typed .NET objects. (#681)
  Related properties contain typed objects, while custom fields and entity-property values retain the data supplied by Jira.
- Issue, user, group, project, version, and filter inputs accept typed objects and supported identifier/name shorthand.
  User identifiers resolve as Cloud account IDs or Data Center usernames.
  `Get-JiraVersion` accepts version objects or integer/string version IDs through the pipeline, and project objects to list project versions.
- Filter retrieval, removal, and permission commands accept typed filters or filter IDs, with identifier aliases and pipeline support.
  Permission operations use the supplied credentials when resolving filters.
  `Remove-JiraFilterPermission` accepts `-Filter` (aliases `-FilterId`, `-Id`) and optional typed `-Permission` values (alias `-PermissionId`), and validates all permission IDs before deleting any permissions.
- `Add-JiraIssueComment` and `Add-JiraIssueWorklog` accept typed role/group `-Visibility`, with `-VisibleRole` retained as an alias.
  `All Users` leaves comments and worklogs unrestricted whether supplied as a role object or a string.
- Cloud comments and issue descriptions accept Markdown and are converted to Atlassian Document Format.
  Worklog and transition comments, and rich-text values supplied through `-Fields`, also use Cloud-compatible ADF payloads.
  Data Center retains plain-text/wiki-markup behavior, and returned worklog comments remain readable strings. (#602)
- `New-JiraIssue`, `Set-JiraIssue`, and `Invoke-JiraIssueTransition` resolve `-Fields` names against the relevant create, edit, or transition screen metadata before falling back to the global field catalogue.
  This reduces ambiguity when custom fields share display names.
- `Get-JiraIssueCreateMetadata` uses Cloud REST API v3 and Data Center v2, reads the deployment-specific response shape, and follows pagination.
  `-First`, `-Skip`, and `-IncludeTotalCount` work across page boundaries. (#651)
- Paged requests emit total counts before results, using Jira's full total or an unknown count when the API omits it.
- `New-JiraIssue` delegates required-field validation to Jira's create endpoint, allowing server defaults and avoiding rejection of UI-only required fields.
  Jira's field-level validation errors are included in error messages. (#336)
- `New-JiraIssue` resolves priority names to IDs and reports `ParameterValue.InvalidPriority` for unknown or ambiguous names.
  Reporter usernames are also resolved on Data Center before issue creation.
- `Get-JiraGroup` uses the supported Cloud and Data Center endpoints, reports non-terminating `GroupNotFound` errors for missing groups, and returns `Group.Id` with `GroupId` retained as an alias. (#606)
- Group member and removal commands accept group names directly, using known group IDs on Cloud where available. (#606)
- Attachment uploads preserve non-ASCII filenames. (#607)
- `Invoke-JiraMethod` accepts absolute URLs and relative endpoints beginning with `/`, resolving relative paths against the selected connection's Jira endpoint.
- HTTP retries cover 429 and 503 responses, vary retry timing, and cap delays at 60 seconds. (#576)
- Jira error parsing supports `message`, `errorMessage`, `errorMessages`, and field-level `errors`. (#576)

### Fixed

- PowerShell 7 HTTP errors without `ErrorDetails` report the HTTP status; Windows PowerShell 5.1 retains stream-based error parsing. (#604)
- `Invoke-JiraIssueTransition` reports unresolved transitions, including issues with no available transitions.
- Query keys, query values, and status names are percent-encoded, with spaces encoded as `%20`.
  Unicode and long values are supported on Windows PowerShell 5.1; query parsing preserves values containing `=`.
  Empty query parameters do not append a trailing `?`.
- `Get-JiraIssue` accepts pipeline input by `Key` property to refresh issues without prompting.
  `Remove-JiraIssueAttachment` binds piped attachments to their IDs.
- Version creation omits absent start and release dates from the request payload.
- Missing server build dates and server times return `$null`.
- Pagination returns partial results with a warning when Jira returns a null response.
- Concurrent module imports handle configuration-file creation safely, and configuration parsing accepts CRLF and LF line endings.
- `Get-JiraIssueEditMetadata` reports the supplied issue when lookup fails.
- Generated help accurately reports parameter aliases, pipeline binding, defaults, input/output types, and example code.
  Pipeline documentation matches the accepted inputs, including `New-JiraIssue -Reporter` and attachment upload paths.

### Internal

- Build and test tooling uses AtlassianPS.Standards 0.4.0, Pester 6.2, and PlatyPS 1.0.
  Shared-standards scripts and workflow actions use the version declared in `Tools/build.requirements.psd1`; dependency updates honor `-WhatIf` before bootstrap side effects.
- Shared standards tooling handles help generation, package validation, environment loading, test-module resolution, and release-note extraction.
  `CHANGELOG.md` supplies both GitHub release notes and PSGallery manifest release notes.
- Continuous delivery promotes CI-tested artifacts after release-intent validation.
- Cloud smoke tests run in CI for first-party pull requests and pushes to `master`.
  Full Cloud and Dockerized Data Center integration suites run on a weekly schedule and manual dispatch, with a `track` selector.
  The former `run-integration-tests` label is retired.
- `Invoke-Build -Task Test` excludes integration tests by default.
  `TestIntegration` supports parallel execution, `-Tag`, `-ExcludeTag`, and `-ThrottleLimit`; local Data Center setup is documented in [`Tests/Integration/README.md`](Tests/Integration/README.md).
- Integration tests provision their required issues, filters, comments, and worklogs, discover available workflows, and allow for Jira indexing delays.
  Data Center jobs have a 60-minute timeout and a 25-minute test-step timeout, with logs and test artifacts retained for diagnosis.
  Integration results use the ignored `Test-Integration.xml` filename.
- Unit tests reuse the loaded module when source files are unchanged and use offline HTTP fixtures.
  Build tasks generate help incrementally, remove orphaned help, and limit linting to source directories.
- Markdown is the source for generated command help; build validation checks help completeness and rejects malformed input/output type headings.
- Domain classes compile on module import and remain compatible with Windows PowerShell 5.1.
  Re-imports reuse loaded types and report incompatible partial type assemblies.
  Module packages must include the class source files, and hosts must permit `Add-Type` compilation.
- Removed the custom JSON converter, legacy `Accept` header workaround, and BuildHelpers dependency.
  Internal `Invoke-JiraMethod` parameters are hidden from tab completion.

## 2.16 - 2026-04-13

### Added

- Added Jira Cloud compatibility — the module now auto-detects Cloud vs Data Center/Server via `Get-JiraServerInformation` and adapts API calls accordingly
- Added `ConvertFrom-AtlassianDocumentFormat` public function (alias `ConvertFrom-ADF`) — converts ADF objects (Jira Cloud v3) to Markdown; plain strings (Data Center) are passed through unchanged
- Added `ConvertTo-AtlassianDocumentFormat` public function (alias `ConvertTo-ADF`) — converts Markdown to ADF for writing descriptions and comments on Jira Cloud v3
- Added `-AccountId` parameter to `Get-JiraUser` for Cloud's account-based user lookup
- Added `-Force` parameter to `Get-JiraServerInformation` to bypass the server info cache
- Added HTTP 429 rate limit handling with automatic retry (respects `Retry-After` header, exponential backoff)
- Added Jira Cloud vs Data Center compatibility guidance in documentation

### Changed

- User operations now use `accountId` on Cloud, `username`/`name` on Data Center (`Get-JiraUser`, `Set-JiraUser`, `Remove-JiraUser`, `New-JiraIssue`, `Set-JiraIssue`, `Invoke-JiraIssueTransition`, `Add-JiraGroupMember`, `Remove-JiraGroupMember`, `Add-JiraIssueWatcher`, `Remove-JiraIssueWatcher`, `Resolve-JiraUser`)
- `Get-JiraIssue` JQL search uses `/rest/api/3/search/jql` with token-based pagination on Cloud
- `Get-JiraServerInformation` now caches its result in module scope; subsequent calls return cached data (cleared on `Set-JiraConfigServer` or with `-Force`)
- `ConvertTo-JiraComment` and `ConvertTo-JiraIssue` now convert ADF responses to readable Markdown text
- `ConvertTo-JiraUser.ToString()` falls back to `DisplayName` or `AccountId` when `Name` is empty (GDPR compliance)
- `Get-JiraIssueWatcher` now pipes watchers through `ConvertTo-JiraUser` for consistent typed output
- Modernized test infrastructure and standardized helper utilities (#549)
- Bumped GitHub Actions: `actions/upload-artifact` v7, `actions/download-artifact` v8, `dawidd6/action-download-artifact` v19

### Fixed

- Enforced UTF-8 with BOM across all PowerShell files for PS v5 compatibility (#574)
- Fixed `inlineCard` rendering in `ConvertFrom-ADF` to produce `<url>` instead of redundant `[url](url)`
- Fixed table separator regex in `ConvertTo-ADF` to handle compact separators without spaces
- Fixed typos and casing errors in test assertions and fixtures (#566)

## 2.15 - 2025-12-30

### Added

- Added `-Components` to `New-JiraIssue`. This will be a comma-separated list of Component IDs. (#483, [@micheleliberman])
- Added `Get-JiraIssueWorklog` (#451, [@asherber])
- Allow `New-JiraSession` to be called without `-Credential` so to use `-Header` (#439, [@pwshmatt])

### Changed

- Improved `-Transition` behavior in `Invoke-JiraIssueTransition` (#416, [@Rufus125])
- Updated Pester to v5 (#543, [@SrBlackVoid])

### Fixed

- Fixed example and improved documentation on `-Properties` hashtable for `Set-JiraUser` (#509, [@jschlackman])
- Fixed `Get-JiraIssueCreateMetadata` to conform with Atlassian's API changes ([documentation](https://confluence.atlassian.com/jiracore/createmeta-rest-endpoint-to-be-removed-975040986.html)) (#488, [@robertmbaker])
- Removed `reporter` from `New-JiraIssue` when project is "next-gen" (#407, [@LaurentGoderre])
- Fixed `-ErrorAction` in `Add-JiraGroupMember` (#426, [@spascoe])
- Fixed copy/paste error in test files for `Get-JiraIssue` (#427, [@borislol])
- Fixed JSON conversion in `Invoke-JiraIssueTransition` (#417, [@Rufus125])
- Fixed type in `Invoke-JiraIssueTransition` (#417, [@Rufus125])

## 2.14 - 2020-03-28

### Changed

- Changed all commands to only use Jira's api version 2. (#409, [@lipkau])
  This is a temporary fix and should be reverted to version `latest` as soon as
  a proper handling of how users work between cloud and on-premise is
  implemented

## 2.13 - 2020-02-23

### Added

- Add support for activation/deactivation of accounts via `Set-JiraUser` (#385, [@johnheusinger])

### Changed

- Removed progress bar from `Invoke-WebRequest` for better performance (#380, [@sgtwilko])

## 2.12 - 2019-08-15

### Added

- Added cmdlet for sorting versions: `Move-JiraVersion` (#363, [@kb-cs])
- Added cmdlet for finding filters by name: `Find-JiraFilter` (#365, [@vercellone])

### Changed

- Changed the way users as interpreted by functions (#369, [@lipkau])
- Changed how the config of a jira server is stored (#370, [@lipkau])

## 2.11 - 2019-07-02

### Added

- Unit test for synopsis in cmdlet documentation (#344, [@alexsuslin])

### Changed

- `Invoke-JiraIssueTransition` to find username with exact match (#351, [@mirrorgleam])
- Fixed `-Add <String>` parameter for `Set-JiraIssueLabel` on issues without labels (#358, [@lipkau])

## 2.10 - 2019-02-21

### Added

- Parameter for retrieving information about a specific user with `Get-JiraUser` (#328, [@michalporeba])
  - this implementations will be changed with the next major update in favor of #306

### Changed

- Fixed logic of how to retrieve components from project (#330, [@lipkau])
- Fix usage of `New-JiraIssue` in Jira Environment with mixed classic and "next gen" projects (#337, [@nojp])
- Fixed `Get-JiraIssueAttachmentFile` to use `Accept` header based on Mime time of attachment (#333, [@wisemoth])
- Fixed incorrect handling of skip notifications when updating an issue (#339, [@lipkau])

## 2.9 - 2018-12-12

### Added

- Parameter for selecting what fields to return the the issue's payload (#300, [@tuxgoose])
- Added pipeline support to `New-JiraIssue` (#312, [@ctolan])
- Added parameter to avoid notifying user when running `Set-JiraIssue` (#315, [@alexsuslin])
- Improved documentation to demonstrate how to authenticate with 2FA (#313, [@lipkau])
- Added function to download attachments from issue: `Get-JiraIssueAttachmentFile` (#323, [@lipkau])

### Changed

- Fixed the way a user is resolved in `Remove-JiraGroupMember` (#301, [@lipkau])
- Improved the resolving of server responses with an error (#303, [@lipkau])
- Fixed payload of `New-JiraFilter` (#304, [@lipkau])
- Fixed paging when server responds with only 1 result (#307, [@lipkau])
- Fixed `Set-JiraIssue` to allow to unassigned an issue (#309, [@lipkau])
- Changed CI/CD pipeline from AppVeyor to Azure DevOps (#317, [@lipkau])
- Fixed missing properties on `Get-JiraUser` (#321, [@lipkau])
- Fixed `-DateStarted` on `Add-JiraIssueWorklog` (#324, [@lipkau])

## 2.8 - 2018-06-28

More detailed description about the changes can be found on [Our Website](https://atlassianps.org/article/announcement/JiraPS-v2.8.html).

### Changed

- Added support for paginated response from API server by means of `-Paging` (#291, [@lipkau[]])
- Added full set of functions to manage Filter Permissions (#289, [@lipkau[]])
- Added `-Id` parameter to `Remove-JiraFilter` (#288, [@lipkau[]])
- Changed logic of `Get-JiraUser` to return multiple results for a search (#272, [@lipkau[]])
- Added posts for homepage to the module's repository (#268, [@lipkau[]])
- Improved handling of _Credentials_ (#271, [@lipkau[]])
- Added missing interactions with _Filters_ (#266, [@lipkau[]])
- Added `Remove-JiraIssue` (#265, [@hmmwhatsthisdo[]])
- Improved Build script (to deploy changes to the homepage) (#259, [@lipkau[]])

### Fixed

- Reverted `Add-JiraIssueAttachment` as JiraPS v2.7 broke it (#287, [@lipkau[]])
- Fixed resolving of Remote Link (#286, [@lipkau[]])
- Improved error handling for ErrorDetails and non-JSON/HTML responses (#277, [@hmmwhatsthisdo[]])
- Fully support Powershell v3 (#273, [@lipkau[]])
- Fixed parameter used in documentation but not in code (#263, [@lipkau[]])

## 2.7 - 2018-05-13

More detailed description about the changes can be found on [Our Website](https://atlassianps.org/article/announcement/JiraPS-v2.7.html).

### Changed

- Writing and throwing of errors show better context (#199, [@lipkau][])
- Improved validation of parameters in `Add-JiraGroupMember` (#250, [@WindowsAdmin92][])
- Improved casting to `-Fields` by defining it's type as `[PSCustomObject]` (#255, [@lipkau][])
- Several improvements to the CI pipeline (#252, #257, [@lipkau][])

### Fixed

- Build script was not publishing to the PSGallery (#252, [@lipkau][])
- Build script was publishing a new tag to repository even in case the build failed (#252, [@lipkau][])
- Fixed the adding multiple labels and the removal of those in `Set-JiraIssueLabel` (#244, [@lipkau][])
- Fixed CI icon in README (#245, [@lipkau][])
- Allow `Get-JiraUser` to return more than 1 result (#246, [@lipkau][])

## 2.6 - 2018-05-02

More detailed description about the changes can be found on [Our Website](https://atlassianps.org/article/announcement/JiraPS-v2.6.html).

### Added

- `-Passthru` parameter to `Invoke-JiraIssueTransition` (#239, [@lipkau][])
- `Get-JiraUser` functionality to find the current user (#231, [@lipkau][])
- full support for PowerShell Core (v6) and Linux/MacOS support (#230, [@lipkau][])
- JiraPS documentation on the homepage (#230, [@lipkau][])

### Changed

- Exposed `Invoke-JiraMethod` as a public function (#233, [@lipkau][])
- Migrated to External Help (instead of Comment-Based Help) (#230, [@lipkau][])

### Fixed

- Index Into Null Object (#209, [@lipkau][])
- Fix empty header (#206, [@lipkau][])
- Bad Body (#224, [@lipkau][])
- Add Labels to array (#226, [@lipkau][])
- Fix removing labels with `Set-JiraIssueLabel -Remove` (#244, [@lipkau][])
- Fix adding of multiple labels at once with `Set-JiraIssueLabel -Add` (#244, [@lipkau][])

## 2.5 - 2018-03-23

More detailed description about the changes can be found on [Our Website](https://atlassianps.org/article/announcement/JiraPS-v2.5.html).

### Changed

- Harmonized code style (#162, [@lipkau][])
- Harmonized verbose messages (#162, [@lipkau][])
- Harmonized debug messages (#162, [@lipkau][])
- Improved debug behavior (#162, [@lipkau][])
- Update of VS code config to reflect code styling (#162, [@lipkau][])
- Few improvements in test cases (#162, [@lipkau][])
- Added parameter validation (#162, [@lipkau][])
- Updated manifest (#162, [@lipkau][])
- Minor preparations for pwsh support (#162, [@lipkau][])
- Execute Tests against `./Release` (#162, [@lipkau][])
- Removed unused `$ConfigFile` variable (#219, [@lipkau][])
- `Invoke-JiraMethod` now sets the TLS to 1.2 before every call (#84, [@lipkau][])
- Fixed _date_ and _timespan_ representation in _Body_ of `Add-JiraIssueWorklog` (#214, [@lipkau][])
- Improved output of `Get-JiraProject` (#216, [@lipkau][])

## 2.4 (Nov 01, 2017)

### Added

- `Add-JiraIssueAttachment`: Add an attachment to an issue (#137, [@beaudryj][])
- `Get-JiraIssueAttachment`: Get attachments from issues (#137, [@beaudryj][])
- `Remove-JiraIssueAttachment`: Remove attachments from issues (#137, [@beaudryj][])

### Changed

- `JiraPS.Issue` now has a property for Attachments `JiraPS.Attachment` (#137, [@beaudryj][])

## 2.3 (Okt 07, 2017)

### Added

- `Get-JiraServerInformation`: Fetches the information about the server (#187, [@lipkau][])

### Changed

- Added `-AddComment` to `Set-JiraIssue`. Allowing the user to write a comment for the changes to the issue (#167, [@Clijsters][])
- Changed the default visibility of comments (#172, [@lipkau][])
- Added more properties to `JiraPS.User` objects (#152, [@lipkau][])

## 2.2.0 (Aug 05, 2017)

### Added

- `New-JiraVersion`: Create a new Version in a project (#158, [@Dejulia489][])
- `Get-JiraVersion`: Get Versions of a project (#158, [@Dejulia489][])
- `Set-JiraVersion`: Changes a Version of a project (#158, [@Dejulia489][])
- `Remove-JiraVersion`: Removes a Version of a project (#158, [@Dejulia489][])
- New custom object for Versions (#158, [@Dejulia489][])

## 2.1.0 (Jul 25, 2017)

### Added

- `Get-JiraIssueEditMetadata`: Returns metadata required to create an issue in JIRA (#65, [@lipkau][])
- `Get-JiraRemoteLink`: Returns a remote link from a JIRA issue (#80, [@lipkau][])
- `Remove-JiraRemoteLink`: Removes a remote link from a JIRA issue (#80, [@lipkau][])
- `Get-JiraComponent`: Returns a Component from JIRA (#68, [@axxelG][])
- `Add-JiraIssueWorklog`: Add worklog items to an issue (#83, [@jkknorr][])
- Added support for getting and managing Issue Watchers (`Add-JiraIssueWatcher`, `Get-JiraIssueWatcher`, `Remove-JiraIssueWatcher`) (#73, [@ebekker][])
- Added IssueLink functionality (`Add-JiraIssueLink`, `Get-JiraIssueLink`, `Get-JiraIssueLinkType`, `Remove-JiraIssueLink`) (#131, [@lipkau][])

### Changed

- `New-JiraIssue`: _Description_ and _Priority_ are no longer mandatory (#53, [@brianbunke][])
- Added property `Components` to `PSjira.Project` (#68, [@axxelG][])
- `Invoke-JiraIssueTransition`: add support for parameters _Fields_, _Comment_ and _Assignee_ (#38, [@padgers][])
- `New-JiraIssue`: support parameter _FixVersion_ (#103, [@Dejulia489][])
- `Set-JiraIssue`: support parameter _FixVersion_ (#103, [@Dejulia489][])
- Respect the global `$PSDefaultParameterValues` inside the module (#110, [@lipkau][])
- `New-JiraSession`: Display warning when login needs CAPTCHA (#111, [@lipkau][])
- Switched to _Basic Authentication_ when generating the session (#116, [@lipkau][])
- Added more tests for the CI (#142, [@lipkau][])

### Fixed

- `Invoke-JiraMethod`: Error when Invoke-WebRequest returns '204 No content' (#42, [@colhal][])
- `Invoke-JiraIssueTransition`: Error when Invoke-WebRequest returns '204 No content' (#43, [@colhal][])
- `Set-JiraIssueLabel`: Forced label property to be an array (#88, [@kittholland][])
- `Invoke-JiraMethod`: Send ContentType as Parameter instead of in the Header (#121, [@lukhase][])

## 2.0 (Jun 24, 2017)

### Changes to the code module

- Move module to organization `AtlassianPS`
- Rename of the module to `JiraPS` **breaking change**
- Rename of module's custom objects to `JiraPS.*` **breaking change**

## 1.2.5 (Aug 08, 2016)

### Changed

- New-JiraIssue: Priority and Description are no longer mandatory (#24, @lipkau)
- New-JiraIssue: Added -Parent parameter for sub-tasks (#29, @ebekker)

### Fixed

- ConvertTo-JiraProject: updated for Atlassian's minor wording change of projectCategory (#31, @alexsuslin)
- Invoke-JiraMethod: now uses the -ContentType parameter instead of manually passing the Content-Type header (#19)
- New-JiraIssue: able to create issues without labels again (#21)
- Set-JiraIssue: fixed issue with JSON depth for custom parameters (#17, @ThePSAdmin)
- Various: Fixed issues with ConvertFrom-Json max length with a custom ConvertFrom-Json function (#23, @LiamLeane)

## 1.2.4 (Dec 10, 2015)

### Changed

- Get-JiraGroupMember: now returns all members by default, with support for -MaxResults and -StartIndex parameters (#14)
- Get-JiraIssue: significantly increased performance (#12)

### Fixed

- Get-JiraIssue: fixed issue where Get-JiraIssue would only return one result when using -Filter parameter in some cases (#15)
- Invoke-JiraIssueTransition: fixed -Credential parameter (#13)

## 1.2.3 (Dec 02, 2015)

### Added

- Get-JiraIssue: added paging support with the -StartIndex and -PageSize parameters. This allows programmatically looping through all issues that match a given search. (#9)

### Changed

- Get-JiraIssue: default behavior has been changed to return all issues via paging when using -Query or -Filter parameters

### Fixed

- Invoke-JiraMethod: Fixed issue where non-standard characters were not being parsed correctly from JSON (#7)

## 1.2.2 (Nov 16, 2015)

### Added

- Set-JiraIssueLabel: add and remove specific issue labels, or overwrite or clear all labels on an issue (#5)

### Changed

- New-JiraIssue: now has a -Label parameter
- Set-JiraIssue: now has a -Label parameter (this replaces all labels on an issue; use Set-JiraIssueLabel for more fine-grained control)
- Invoke-JiraMethod: handles special UTF-8 characters correctly (#4)

### Fixed

- Get-JiraIssueCreateMetadata: now correctly returns the ID of fields as well (#6)

## 1.2.0 (Oct 26, 2015)

### Changed

- Get-JiraIssueCreateMetadata: changed output type from a generic PSCustomObject to new type PSJira.CreateMetaField
- Get-JiraIssueCreateMetadata: now returns additional properties for field metadata, such as AllowedValues

## 1.2.0 (Oct 16, 2015)

### Added

- Get-JiraFilter: get a reference to a JIRA filter, including its JQL and owner

### Changed

- Get-JiraIssue: now supports a -Filter parameter to obtain all issues matching a given filter object or ID

## 1.1.1 (Oct 08, 2015)

### Changed

- Set-JiraIssue now supports modifying arbitrary fields through the Fields parameter

## 1.1.0 (Sep 17, 2015)

### Added

- User management: create and delete users and groups, and modify group memberships

### Changed

- Cleaner error handling in all REST requests; Jira's error messages should now be passed as PowerShell errors

### Fixed

- PSJira.User: ToString() now works as expected

## 1.0.0 (Aug 5, 2015)

- Initial release

This changelog is inspired by the [Pester](https://github.com/pester/Pester/blob/master/CHANGELOG.md) file,
which is in turn inspired by the [Vagrant](https://github.com/mitchellh/vagrant/blob/master/CHANGELOG.md) file.

## Template

## Next Release

### Added

### Changed

### Fixed

<!-- reference-style links -->

[@alexsuslin]: https://github.com/alexsuslin
[@asherber]: https://github.com/asherber
[@axxelg]: https://github.com/axxelG
[@beaudryj]: https://github.com/beaudryj
[@borislol]: https://github.com/borislol
[@brianbunke]: https://github.com/brianbunke
[@clijsters]: https://github.com/Clijsters
[@colhal]: https://github.com/colhal
[@copilot]: https://github.com/copilot
[@ctolan]: https://github.com/ctolan
[@dejulia489]: https://github.com/Dejulia489
[@ebekker]: https://github.com/ebekker
[@hmmwhatsthisdo]: https://github.com/hmmwhatsthisdo
[@jkknorr]: https://github.com/jkknorr
[@johnheusinger]: https://github.com/johnheusinger
[@jschlackman]: https://github.com/jschlackman
[@kb-cs]: https://github.com/kb-cs
[@kittholland]: https://github.com/kittholland
[@LaurentGoderre]: https://github.com/LaurentGoderre
[@liamleane]: https://github.com/LiamLeane
[@lipkau]: https://github.com/lipkau
[@lukhase]: https://github.com/lukhase
[@michalporeba]: https://github.com/michalporeba
[@micheleliberman]: https://github.com/micheleliberman
[@mirrorgleam]: https://github.com/mirrorgleam
[@nojp]: https://github.com/nojp
[@padgers]: https://github.com/padgers
[@pwshmatt]: https://github.com/pwshmatt
[@robertmbaker]: https://github.com/robertmbaker
[@Rufus125]: https://github.com/Rufus125
[@sgtwilko]: https://github.com/sgtwilko
[@spascoe]: https://github.com/spascoe
[@SrBlackVoid]: https://github.com/SrBlackVoid
[@thepsadmin]: https://github.com/ThePSAdmin
[@tuxgoose]: https://github.com/tuxgoose
[@vercellone]: https://github.com/vercellone
[@windowsadmin92]: https://github.com/WindowsAdmin92
[@wisemoth]: https://github.com/wisemoth
