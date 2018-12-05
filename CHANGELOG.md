# Change Log

## [2.8] - 2018-06-28

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

## [2.7] - 2018-05-13

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

## [2.6] - 2018-05-02

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
- Fix removing labels with `Set-JiraIssueLabel -Remove` (#244, [lipkau][])
- Fix adding of multiple labels at once with `Set-JiraIssueLabel -Add` (#244, [lipkau][])

## [2.5] - 2018-03-23

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

## [2.4] (Nov 01, 2017)

### Added

- `Add-JiraIssueAttachment`: Add an attachment to an issue (#137, [@beaudryj][])
- `Get-JiraIssueAttachment`: Get attachments from issues (#137, [@beaudryj][])
- `Remove-JiraIssueAttachment`: Remove attachments from issues (#137, [@beaudryj][])

### Changed

- `JiraPS.Issue` now has a property for Attachments `JiraPS.Attachment` (#137, [@beaudryj][])

## [2.3] (Okt 07, 2017)

### Added

- `Get-JiraServerInformation`: Fetches the information about the server (#187, [@lipkau][])

### Changed

- Added `-AddComment` to `Set-JiraIssue`. Allowing the user to write a comment for the changes to the issue (#167, [@Clijsters][])
- Changed the default visibility of comments (#172, [@lipkau][])
- Added more properties to `JiraPS.User` objects (#152, [@lipkau][])

## [2.2].0 (Aug 05, 2017)

### Added

- `New-JiraVersion`: Create a new Version in a project (#158, [@Dejulia489][])
- `Get-JiraVersion`: Get Versions of a project (#158, [@Dejulia489][])
- `Set-JiraVersion`: Changes a Version of a project (#158, [@Dejulia489][])
- `Remove-JiraVersion`: Removes a Version of a project (#158, [@Dejulia489][])
- New custom object for Versions (#158, [@Dejulia489][])

## [2.1].0 (Jul 25, 2017)

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

## [2.0].0 (Jun 24, 2017)

### Changes to the code module

- Move module to organization `AtlassianPS`
- Rename of the module to `JiraPS` **breaking change**
- Rename of module's custom objects to `JiraPS.*` **breaking change**

## [1.2].5 (Aug 08, 2016)

### Changed

- New-JiraIssue: Priority and Description are no longer mandatory (#24, @lipkau)
- New-JiraIssue: Added -Parent parameter for sub-tasks (#29, @ebekker)

### Fixed

- ConvertTo-JiraProject: updated for Atlassian's minor wording change of projectCategory (#31, @alexsuslin)
- Invoke-JiraMethod: now uses the -ContentType parameter instead of manually passing the Content-Type header (#19)
- New-JiraIssue: able to create issues without labels again (#21)
- Set-JiraIssue: fixed issue with JSON depth for custom parameters (#17, @ThePSAdmin)
- Various: Fixed issues with ConvertFrom-Json max length with a custom ConvertFrom-Json function (#23, @LiamLeane)

## [1.2].4 (Dec 10, 2015)

### Changed

- Get-JiraGroupMember: now returns all members by default, with support for -MaxResults and -StartIndex parameters (#14)
- Get-JiraIssue: significantly increased performance (#12)

### Fixed

- Get-JiraIssue: fixed issue where Get-JiraIssue would only return one result when using -Filter parameter in some cases (#15)
- Invoke-JiraIssueTransition: fixed -Credential parameter (#13)

## [1.2].3 (Dec 02, 2015)

### Added

- Get-JiraIssue: added paging support with the -StartIndex and -PageSize parameters. This allows programmatically looping through all issues that match a given search. (#9)

### Changed

- Get-JiraIssue: default behavior has been changed to return all issues via paging when using -Query or -Filter parameters

### Fixed

- Invoke-JiraMethod: Fixed issue where non-standard characters were not being parsed correctly from JSON (#7)

## [1.2].2 (Nov 16, 2015)

### Added

- Set-JiraIssueLabel: add and remove specific issue labels, or overwrite or clear all labels on an issue (#5)

### Changed

- New-JiraIssue: now has a -Label parameter
- Set-JiraIssue: now has a -Label parameter (this replaces all labels on an issue; use Set-JiraIssueLabel for more fine-grained control)
- Invoke-JiraMethod: handles special UTF-8 characters correctly (#4)

### Fixed

- Get-JiraIssueCreateMetadata: now correctly returns the ID of fields as well (#6)

## [1.2].1 (Oct 26, 2015)

### Changed

- Get-JiraIssueCreateMetadata: changed output type from a generic PSCustomObject to new type PSJira.CreateMetaField
- Get-JiraIssueCreateMetadata: now returns additional properties for field metadata, such as AllowedValues

## [1.2].0 (Oct 16, 2015)

### Added

- Get-JiraFilter: get a reference to a JIRA filter, including its JQL and owner

### Changed

- Get-JiraIssue: now supports a -Filter parameter to obtain all issues matching a given filter object or ID

## [1.1].1 (Oct 08, 2015)

### Changed

- Set-JiraIssue now supports modifying arbitrary fields through the Fields parameter

## [1.1].0 (Sep 17, 2015)

### Added

- User management: create and delete users and groups, and modify group memberships

### Changed

- Cleaner error handling in all REST requests; Jira's error messages should now be passed as PowerShell errors

### Fixed

- PSJira.User: ToString() now works as expected

## [1.0].0 (Aug 5, 2015)

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
  [@axxelG]: https://github.com/axxelG
  [@beaudryj]: https://github.com/beaudryj
  [@brianbunke]: https://github.com/brianbunke
  [@Clijsters]: https://github.com/Clijsters
  [@colhal]: https://github.com/colhal
  [@Dejulia489]: https://github.com/Dejulia489
  [@ebekker]: https://github.com/ebekker
  [@hmmwhatsthisdo]: https://github.com/hmmwhatsthisdo
  [@jkknorr]: https://github.com/jkknorr
  [@kittholland]: https://github.com/kittholland
  [@LiamLeane]: https://github.com/LiamLeane
  [@lipkau]: https://github.com/lipkau
  [@lukhase]: https://github.com/lukhase
  [@padgers]: https://github.com/padgers
  [@ThePSAdmin]: https://github.com/ThePSAdmin
  [@WindowsAdmin92]: https://github.com/WindowsAdmin92
