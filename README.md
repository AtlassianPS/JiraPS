---
layout: module
permalink: /module/JiraPS/
---

# [JiraPS](https://atlassianps.org/module/JiraPS)

[![Build status](https://ci.appveyor.com/api/projects/status/9s62lxho77ukry8a/branch/master?svg=true)](https://ci.appveyor.com/project/AtlassianPS/jiraps/branch/master)

JiraPS is a Windows PowerShell module to interact with [Atlassian JIRA](https://www.atlassian.com/software/jira) via a REST API, while maintaining a consistent PowerShell look and feel.

Join the conversation on [![SlackLogo][] AtlassianPS.Slack.com](https://atlassianps.org/slack)

[SlackLogo]: https://atlassianps.org/assets/img/Slack_Mark_Web_28x28.png
<!--more-->

---

## Instructions

### Installation

Install JiraPS from the [PowerShell Gallery]! `Install-Module` requires PowerShellGet (included in PS v5, or download for v3/v4 via the gallery link)

```powershell
# One time only install: (requires an admin PowerShell window)
Install-Module JiraPS

# Check for updates occasionally:
Update-Module JiraPS

# To use each session:
Import-Module JiraPS
Set-JiraConfigServer 'https://YourCloudWiki.atlassian.net'
New-JiraSession -Credential $cred
```

### Usage

You can find the full documentation on our [homepage](https://atlassianps.org/docs/JiraPS) and in the console.
```powershell
# Review the help at any time!
Get-Help about_JiraPS
Get-Command -Module JiraPS
Get-Help Get-JiraIssue -Full   # or any other command
```

For first steps to get up and running, check out the [Getting Started](https://atlassianps.org/docs/JiraPS/Getting_Started.html) page.

### Contribute

Want to contribute to AtlassianPS? Great!
We appreciate [everyone](https://atlassianps.org/#people) who invests their time to make our modules the best they can be.

Check out our guidelines on [Contributing](https://atlassianps.org/docs/Contributing.html) to our modules and documentation.

## Acknowledgments

* Thanks to [replicaJunction] for getting this module on it's feet
* Thanks to everyone ([Our Contributors](https://atlassianps.org/#people)) that helped with this module

## Useful links

* [Source Code]
* [Latest Release]
* [Submit an Issue]
* How you can help us: [List of Issues](https://github.com/AtlassianPS/ConfluencePS/issues?q=is%3Aissue+is%3Aopen+label%3Aup-for-grabs)

## Disclaimer

Hopefully this is obvious, but:
> This is an open source project (under the [MIT license]), and all contributors are volunteers. All commands are executed at your own risk. Please have good backups before you start, because you can delete a lot of stuff if you're not careful.

  [Confluence]: <https://www.atlassian.com/software/confluence>
  [REST API]: <https://docs.atlassian.com/atlassian-confluence/REST/latest/>
  [PowerShell Gallery]: <https://www.powershellgallery.com/>
  [thomykay]: <https://github.com/thomykay>
  [PoshConfluence]: <https://github.com/thomykay/PoshConfluence>
  [RamblingCookieMonster]: <https://github.com/RamblingCookieMonster>
  [PSStackExchange]: <https://github.com/RamblingCookieMonster/PSStackExchange>
  [Source Code]: <https://github.com/AtlassianPS/ConfluencePS>
  [Latest Release]: <https://github.com/AtlassianPS/ConfluencePS/releases/latest>
  [Submit an Issue]: <https://github.com/AtlassianPS/ConfluencePS/issues/new>
  [juneb]: <https://github.com/juneb>
  [brianbunke]: <https://github.com/brianbunke>
  [Check this out]: <https://github.com/juneb/PowerShellHelpDeepDive>
  [MIT license]: <https://github.com/brianbunke/ConfluencePS/blob/master/LICENSE>

<!-- [//]: # (Sweet online markdown editor at http://dillinger.io) -->
<!-- [//]: # ("GitHub Flavored Markdown" https://help.github.com/articles/github-flavored-markdown/) -->
