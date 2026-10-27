---
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/
hide: true
---
# JiraPS

## about_JiraPS

# SHORT DESCRIPTION

JiraPS is a PowerShell module to interact with Atlassian JIRA via a REST API, while maintaining a consistent PowerShell look and feel.

# LONG DESCRIPTION

Jira is an issuetracker from Atlassian.
JiraPS is a Powershell implementation to interact with it's API.

JiraPS can be used by any user.
The Jira server will check if the authenticated user has the necessary permissions to perform the action.
This allows JiraPS to be used by system administrators (eg: to create new Users), project administrators (eg: to create new Versions) and users (eg: to create or view an issue).

## GETTING STARTED

Create a named connection with the authentication method supported by your Jira deployment.
For Jira Cloud, supply your site URL, authentication email and API token:

```powershell
$token = Read-Host 'Jira API token' -AsSecureString
$work = Connect-Jira -Name work -Uri 'https://work.atlassian.net' -EmailAddress 'you@example.com' -ApiToken $token
Get-JiraIssue -Key PROJ-1
```

The first successful connection becomes the Jira default.
Subsequent commands use that connection when Connection is omitted.

For Data Center with a personal access token, connect to the Data Center endpoint:

```powershell
$token = Read-Host 'Jira PAT' -AsSecureString
$internal = Connect-Jira -Name internal -Uri 'https://jira.example.com/jira' -PersonalAccessToken $token
Get-JiraIssue -Key PROJ-1 -Connection $internal
```

Passing Connection chooses that connection for one operation and leaves the default unchanged.
JiraPS detects the deployment during connection validation and adapts its API calls accordingly.
See [about_JiraPS_Authentication](about/authentication.html) for username/password, anonymous access, saved profiles, multiple connections and v2 migration examples.

## DISCOVERING YOUR ENVIRONMENT

Finding all projects you have access to:

```powershell
Get-JiraProject
```

Get all issues in a project:

```powershell
Get-JiraIssue -Query "project = CS"
```

See all available information of an issue:

```powershell
Get-JiraIssue "CS-15" | Format-List *
```

> The view of an issue is minimized so that a table-view is easier to read.
> There are a few options to get to see all the properties of an issue.
> Such as the example above.

# EXAMPLES

1. Creating issues from a CSV file

Given a CSV file which looks something like this:

```csv
project,summary,description,assignee
CS,Update Server Config, The config of server "srv1" must be updated, admin
CS,Delete temporary files,, admin
```

Issues can be created for each for the entries above with JiraPS like this:

```powershell
Import-CSV "./data.csv" | Foreach { New-JiraIssue -Project $_.project -Summary $_.summary -Description $_.description -Assignee $_.assignee }
```

2. Set the "fixVersions" of multiple issues at once

```powershell
# Get all versions from the project
$version = Get-JiraVersion -Project TV |
    # Filter by part of the name
    Where {$_.Name -like "1.3"}

# Get all issues we need
Get-JiraIssue -Query 'project = TV AND label = "ReadyForRelease' |
    # Update each issue
    Set-JiraIssue -FixVersion $version.Name
```

# NOTE

This project is run by the volunteer organization AtlassianPS.
We are always interested in hearing from new users!
Find us on GitHub or Slack, and let us know what you think.

# SEE ALSO

[JiraPS on Github](https://github.com/AtlassianPS/JiraPS)

[Jira's REST API documentation](https://developer.atlassian.com/cloud/jira/platform/rest/)

[AtlassianPS org](https://atlassianps.org)

[AtlassianPS Slack team](https://atlassianps.org/slack)

# KEYWORDS

- Jira
- Atlassian
