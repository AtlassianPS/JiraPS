=========
Changelog
=========

2.0.0
=====

Release date: Jun 24, 2017

Changes to the code module
--------------------------

* Move module to organization ``AtlassianPS``
* Rename of the module to ``JiraPS`` [**breaking change**}
* Rename of module's custom objects to ``JiraPS.*`` [**breaking change**]

1.2.5
=====

Release date: Aug 08, 2016

Improvements
------------

* New-JiraIssue: Priority and Description are no longer mandatory (#24, @lipkau)
* New-JiraIssue: Added -Parent parameter for sub-tasks (#29, @ebekker)

Bug Fixes
---------

* ConvertTo-JiraProject: updated for Atlassian's minor wording change of projectCategory (#31, @alexsuslin)
* Invoke-JiraMethod: now uses the -ContentType parameter instead of manually passing the Content-Type header (#19)
* New-JiraIssue: able to create issues without labels again (#21)
* Set-JiraIssue: fixed issue with JSON depth for custom parameters (#17, @ThePSAdmin)
* Various: Fixed issues with ConvertFrom-Json max length with a custom ConvertFrom-Json2 function (#23, @LiamLeane)

1.2.4
=====

Release date: Dec 10, 2015

Improvements
------------

* Get-JiraGroupMember: now returns all members by default, with support for -MaxResults and -StartIndex parameters (#14)
* Get-JiraIssue: significantly increased performance (#12)

Bug Fixes
---------

* Get-JiraIssue: fixed issue where Get-JiraIssue would only return one result when using -Filter parameter in some cases (#15)
* Invoke-JiraIssueTransition: fixed -Credential parameter (#13)

1.2.3
=====

Release date: Dec 02, 2015

Features
--------

* Get-JiraIssue: added paging support with the -StartIndex and -PageSize parameters. This allows programmatically looping through all issues that match a given search. (#9)

Improvements
------------

* Get-JiraIssue: default behavior has been changed to return all issues via paging when using -Query or -Filter parameters

Bug Fixes
---------

* Invoke-JiraMethod: Fixed issue where non-standard characters were not being parsed correctly from JSON (#7)

1.2.2
=====

Release date: Nov 16, 2015

Features
--------

* Set-JiraIssueLabel: add and remove specific issue labels, or overwrite or clear all labels on an issue (#5)

Improvements
------------

* New-JiraIssue: now has a -Label parameter
* Set-JiraIssue: now has a -Label parameter (this replaces all labels on an issue; use Set-JiraIssueLabel for more fine-grained control)
* Invoke-JiraMethod: handles special UTF-8 characters correctly (#4)

Bug Fixes
---------

* Get-JiraIssueCreateMetadata: now correctly returns the ID of fields as well (#6)

1.2.1
=====

Release date: Oct 26, 2015

Improvements
------------

* Get-JiraIssueCreateMetadata: changed output type from a generic PSCustomObject to new type PSJira.CreateMetaField
* Get-JiraIssueCreateMetadata: now returns additional properties for field metadata, such as AllowedValues

1.2.0
=====

Release date: Oct 16, 2015

Features
--------

* Get-JiraFilter: get a reference to a JIRA filter, including its JQL and owner

Improvements
------------

* Get-JiraIssue: now supports a -Filter parameter to obtain all issues matching a given filter object or ID

1.1.1
=====

Release date: Oct 08, 2015

Improvements
------------

* Set-JiraIssue now supports modifying arbitrary fields through the Fields parameter

1.1.0
=====

Release date: Sep 17, 2015

Features
--------

* User management: create and delete users and groups, and modify group memberships

Improvements
------------

* Cleaner error handling in all REST requests; JIRA's error messages should now be passed as PowerShell errors

Bug Fixes
---------

* PSJira.User: ToString() now works as expected

1.0.0
=====

Release date: Aug 5, 2015

* Initial release

Template
========

Release date: Jan 1, 2001

Features
--------

Improvements
------------

Bug Fixes
---------

The format of this changelog is inspired by `Pester's changelog`_, which is in turn inspired by `Vagrant`_.

.. _`Pester's changelog`: https://github.com/pester/Pester/blob/master/CHANGELOG.md
.. _`Vagrant`: https://github.com/mitchellh/vagrant/blob/master/CHANGELOG.md
