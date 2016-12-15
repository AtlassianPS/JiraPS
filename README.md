# PSJira

[![Build status](https://ci.appveyor.com/api/projects/status/rog7nhvpfu58xrxu?svg=true)](https://ci.appveyor.com/project/JoshuaT/psjira)

[![Documentation Status](https://readthedocs.org/projects/psjira/badge/?version=latest)](http://psjira.readthedocs.io/en/latest/?badge=latest)

PSJira is a Windows PowerShell module to interact with [Atlassian JIRA](https://www.atlassian.com/software/jira) via a REST API, while maintaining a consistent PowerShell look and feel.

---

## Project update: December 2016
Life is crazy - especially around the holidays - but I'm hard at work on a pretty significant code and documentation overhaul for version 2.0. I'm not able to commit to a timeline for this - depending on how much needs to get done and how much time I have, it could be very soon, or it could still be a couple months out. PSJira is a passion of mine, but (unfortunately) I've got other responsibilities that often take priority.

Please keep the feedback coming in the Issues page - I'm looking over that very closely - but please don't be offended if I'm not able to get back to you in a timely fashion. The community support and feedback I've received for this module is amazing, and I enjoy working with you all!

---

## Requirements

This module has a hard dependency on PowerShell 3.0.  I have no plans to release a version compatible with PowerShell 2, as I rely heavily on several cmdlets and features added in version 3.0.

## Downloading

Due to the magic of continuous integration, the latest passing build of this project will always be on the PowerShell Gallery. If you have the Package Management module for PowerShell (which comes with PowerShell 5.0), you can install the latest build easily:

```powershell
Install-Module PSJira
```

If you're using PowerShell 3 or 4, consider updating! If that's not an option, consider installing PackageManagement on PowerShell 3 or 4 (you can do so from the [PowerShell gallery](https://www.powershellgallery.com/) using the MSI installer link).

You can also download this module from the Download Zip button on this page.  You'll need to extract the PSJira folder to your $PSModulePath (normally, this is at C:\Users\<username>Documents\WindowsPowerShell\Modules).

Finally, you can check the releases page here on GitHub for "stable" versions, but again, PSGallery will always have the latest (tested) version of the module.

## Getting Started

Before using PSJira, you'll need to define your JIRA server URL.  You will only need to do this once:

```powershell
Set-JiraConfigServer "https://jira.example.com"
```

## Usage

Check out the [Getting Started](https://github.com/replicaJunction/PSJira/wiki/Getting-Started) page on the project wiki for detailed use information.

## Planned features
* Support for multiple config files and/or alternate config file locations
* Possible support for OAuth in addition to HTTP Basic authentication

## Contributing
Want to contribute to PSJira?  Great! Here are a couple of notes regarding contributions:

* PSJira relies heavily upon Pester testing to make sure that changes don't break each other.  Please respect the tests when coding against PSJira.
* Pull requests are much more likely to be accepted if all tests pass.
* If you write a change that causes a test to fail, please explain why the change is appropriate.  Tests are code, just like the module itself, so it's very possbile that they need to be fixed as well.  Bonus points if you also write the fix for the test.
* If implementing a brand-new function or behavior, please write a test for it.

Changes will be merged and released when the module passes all Pester tests, including the module style tests.

## Contact

Feel free to comment on this project here on GitHub using the issues or discussion pages.  You can also check out [my blog](http://replicajunction.github.io/) or catch me on the [PowerShell subreddit](https://www.reddit.com/r/powershell).

*Note:* As with all community PowerShell modules and code, you use PSJira at your own risk.  I am not responsible if your JIRA instance causes a fire in your datacenter (literal or otherwise).
