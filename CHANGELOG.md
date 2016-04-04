## 1.2.4 (Dec 10, 2015)
IMPROVEMENTS:
  - Get-JiraGroupMember: now returns all members by default, with support for -MaxResults and -StartIndex parameters (#14)
  - Get-JiraIssue: significantly increased performance (#12)
  
BUG FIXES:
  - Get-JiraIssue: fixed issue where Get-JiraIssue would only return one result when using -Filter parameter in some cases (#15)
  - Invoke-JiraIssueTransition: fixed -Credential parameter (#13)

## 1.2.3 (Dec 02, 2015)
FEATURES:
  - Get-JiraIssue: added paging support with the -StartIndex and -PageSize parameters. This allows programmatically looping through all issues that match a given search. (#9)

IMPROVEMENTS:
  - Get-JiraIssue: default behavior has been changed to return all issues via paging when using -Query or -Filter parameters

BUG FIXES:
  - Invoke-JiraMethod: Fixed issue where non-standard characters were not being parsed correctly from JSON (#7)

## 1.2.2 (Nov 16, 2015)
FEATURES:
  - Set-JiraIssueLabel: add and remove specific issue labels, or overwrite or clear all labels on an issue (#5)

IMPROVEMENTS:
  - New-JiraIssue: now has a -Label parameter
  - Set-JiraIssue: now has a -Label parameter (this replaces all labels on an issue; use Set-JiraIssueLabel for more fine-grained control)
  - Invoke-JiraMethod: handles special UTF-8 characters correctly (#4)

BUG FIXES:
  - Get-JiraIssueCreateMetadata: now correctly returns the ID of fields as well (#6)

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