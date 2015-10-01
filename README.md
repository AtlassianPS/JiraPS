# PSJira

[![Build status](https://ci.appveyor.com/api/projects/status/rog7nhvpfu58xrxu?svg=true)](https://ci.appveyor.com/project/JoshuaT/psjira)

PSJira is a Windows PowerShell module to interact with [Atlassian JIRA](https://www.atlassian.com/software/jira) via a REST API, while maintaining a consistent PowerShell look and feel.

## Requirements

This module has a hard dependency on PowerShell 3.0.  I have no plans to release a version compatible with PowerShell 2, as I rely heavily on several cmdlets and features added in version 3.0.

## Downloading

In PowerShell 5, it's very simple to download the latest public release of this module:

```powershell
Install-Module PSJira
```

If you're using PowerShell 3 or 4, you can download this module from the Download Zip button on the right.  You'll need to extract the PSJira folder to your $PSModulePath.  Normally, this is at C:\Users\<username>Documents\WindowsPowerShell\Modules.

You can also always feel free to clone the module directly in Git.

## Getting Started

Before using PSJira, you'll need to define your JIRA server URL.  You will only need to do this once:

```powershell
Set-JiraConfigServer "https://jira.example.com"
```

## Usage

Check out the [Getting Started](https://github.com/replicaJunction/PSJira/wiki/Getting-Started) page on the project wiki for detailed use information.

## Planned features

* Support for filters in JIRA
* Support for multiple config files and/or alternate config file locations
* Possible support for OAuth in addition to HTTP Basic authentication

## Contact

Feel free to comment on this project here on GitHub using the issues or discussion pages.  You can also check out [my blog](http://replicajunction.github.io/) or catch me on the [PowerShell subreddit](https://www.reddit.com/r/powershell).

*Note:* As with all community PowerShell modules and code, you use PSJira at your own risk.  I am not responsible if your JIRA instance causes a fire in your datacenter (literal or otherwise).
