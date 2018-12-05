---
layout: module
permalink: /module/JiraPS/
---
# [JiraPS](https://atlassianps.org/module/JiraPS)

[![GitHub release](https://img.shields.io/github/release/AtlassianPS/JiraPS.svg?style=for-the-badge)](https://github.com/AtlassianPS/JiraPS/releases/latest)
[![Build Status](https://img.shields.io/vso/build/AtlassianPS/JiraPS/11/master.svg?style=for-the-badge)](https://dev.azure.com/AtlassianPS/JiraPS/_build/latest?definitionId=11)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/JiraPS.svg?style=for-the-badge)](https://www.powershellgallery.com/packages/JiraPS)
![License](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)

JiraPS is a Windows PowerShell module to interact with Atlassian [JIRA] via a REST API, while maintaining a consistent PowerShell look and feel.

Join the conversation on [![SlackLogo][] AtlassianPS.Slack.com](https://atlassianps.org/slack)

[SlackLogo]: https://atlassianps.org/assets/img/Slack_Mark_Web_28x28.png
<!--more-->

---

## Instructions

### Installation

Install JiraPS from the [PowerShell Gallery]! `Install-Module` requires PowerShellGet (included in PS v5, or download for v3/v4 via the gallery link)

```powershell
# One time only install:
Install-Module JiraPS -Scope CurrentUser

# Check for updates occasionally:
Update-Module JiraPS
```

### Usage

```powershell
# To use each session:
Import-Module JiraPS
Set-JiraConfigServer 'https://YourCloud.atlassian.net'
New-JiraSession -Credential $cred
```

You can find the full documentation on our [homepage](https://atlassianps.org/docs/JiraPS) and in the console.

```powershell
# Review the help at any time!
Get-Help about_JiraPS
Get-Command -Module JiraPS
Get-Help Get-JiraIssue -Full # or any other command
```

For more information on how to use JiraPS, check out the [Documentation](https://atlassianps.org/docs/JiraPS/).

### Contribute

Want to contribute to AtlassianPS? Great!
We appreciate [everyone](https://atlassianps.org/#people) who invests their time to make our modules the best they can be.

Check out our guidelines on [Contributing] to our modules and documentation.

## Tested on

|Configuration|Status|
|-------------|------|
|Windows Powershell v3||
|Windows Powershell v4||
|Windows Powershell v5.1|[![Build Status](https://img.shields.io/vso/build/AtlassianPS/JiraPS/11/master.svg?style=for-the-badge)](https://dev.azure.com/AtlassianPS/JiraPS/_build/latest?definitionId=11)|
|Powershell Core (latest) on Windows|[![Build Status](https://img.shields.io/vso/build/AtlassianPS/JiraPS/11/master.svg?style=for-the-badge)](https://dev.azure.com/AtlassianPS/JiraPS/_build/latest?definitionId=11)|
|Powershell Core (latest) on Ubuntu|[![Build Status](https://img.shields.io/vso/build/AtlassianPS/JiraPS/11/master.svg?style=for-the-badge)](https://dev.azure.com/AtlassianPS/JiraPS/_build/latest?definitionId=11)|
|Powershell Core (latest) on MacOS|[![Build Status](https://img.shields.io/vso/build/AtlassianPS/JiraPS/11/master.svg?style=for-the-badge)](https://dev.azure.com/AtlassianPS/JiraPS/_build/latest?definitionId=11)|

## Acknowledgements

* Thanks to [replicaJunction] for getting this module on it's feet
* Thanks to everyone ([Our Contributors](https://atlassianps.org/#people)) that helped with this module

## Useful links

* [Source Code]
* [Latest Release]
* [Submit an Issue]
* [Contributing]
* How you can help us: [List of Issues](https://github.com/AtlassianPS/JiraPS/issues?q=is%3Aissue+is%3Aopen+label%3Aup-for-grabs)

## Disclaimer

Hopefully this is obvious, but:

> This is an open source project (under the [MIT license]), and all contributors are volunteers. All commands are executed at your own risk. Please have good backups before you start, because you can delete a lot of stuff if you're not careful.

<!-- reference-style links -->
  [JIRA]: https://www.atlassian.com/software/jira
  [PowerShell Gallery]: https://www.powershellgallery.com/
  [Source Code]: https://github.com/AtlassianPS/JiraPS
  [Latest Release]: https://github.com/AtlassianPS/JiraPS/releases/latest
  [Submit an Issue]: https://github.com/AtlassianPS/JiraPS/issues/new
  [replicaJunction]: https://github.com/replicaJunction
  [MIT license]: https://github.com/AtlassianPS/JiraPS/blob/master/LICENSE
  [Contributing]: http://atlassianps.org/docs/Contributing

<!-- [//]: # (Sweet online markdown editor at http://dillinger.io) -->
<!-- [//]: # ("GitHub Flavored Markdown" https://help.github.com/articles/github-flavored-markdown/) -->
