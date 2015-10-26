## 1.2.1 (Oct 26, 2015)
IMPROVEMENTS:
  - Get-JiraIssueCreateMetadata: changed output type from a generic PSCustomObject to new type PSJira.CreateMetaField
  - Get-JiraIssueCreateMetadata: now returns additional properties for field metadata, such as AllowedValues

## 1.2.0 (Oct 16, 2015)

FEATURES:
  - Get-JiraFilter: get a reference to a JIRA filter, including its JQL and owner

IMPROVEMENTS:
  - Get-JiraIssue: now supports a -Filter parameter to obtain all issues matching a given filter object or ID

## 1.1.1 (Oct 08, 2015)

IMPROVEMENTS:
  - Set-JiraIssue now supports modifying arbitrary fields through the Fields parameter

## 1.1.0 (Sep 17, 2015)

FEATURES:
  - User management: create and delete users and groups, and modify group memberships

IMPROVEMENTS:
  - Cleaner error handling in all REST requests; JIRA's error messages should now be passed as PowerShell errors

BUG FIXES:
  - PSJira.User: ToString() now works as expected

## 1.0.0 (Aug 5, 2015)

  - Initial release
  
This changelog is inspired by the 
[Pester](https://github.com/pester/Pester/blob/master/CHANGELOG.md) file, which
is in turn inspired by the 
[Vagrant](https://github.com/mitchellh/vagrant/blob/master/CHANGELOG.md) file.

## Template

  ## Next Release

  FEATURES:

  IMPROVEMENTS:

  BUG FIXES: