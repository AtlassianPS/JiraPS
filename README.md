# PSJira

[![Build status](https://ci.appveyor.com/api/projects/status/utpel25via67xw3b?svg=true)](https://ci.appveyor.com/project/JoshuaT/psjira)
[![Documentation Status](https://readthedocs.org/projects/psjira/badge/?version=latest)](http://psjira.readthedocs.io/en/latest/?badge=latest)

PSJira is a Windows PowerShell module to interact with [Atlassian JIRA](https://www.atlassian.com/software/jira) via a REST API, while maintaining a consistent PowerShell look and feel.

Join the conversation on [![SlackLogo][] PSJira.Slack.com](https://slofile.com/slack/psjira)

[SlackLogo]: assets/Slack_Mark_Web_28x28.png

---

## Documentation on ReadTheDocs

Documentation for PSJira has moved to [ReadTheDocs.io](http://psjira.readthedocs.io). Check it out, and feel free to submit issues or PRs against the documentation as well!

---

## Requirements

This module has a hard dependency on PowerShell 3.0.  There are no plans to release a version compatible with PowerShell 2, as the module relies on several cmdlets and features added in version 3.0.

## Downloading

Due to the magic of continuous integration, the latest passing build of this project will always be on the PowerShell Gallery. If you have the Package Management module for PowerShell (which comes with PowerShell 5.0), you can install the latest build easily:

```powershell
Install-Module PSJira
```

If you're using PowerShell 3 or 4, consider updating! If that's not an option, consider installing PackageManagement on PowerShell 3 or 4 (you can do so from the [PowerShell gallery](https://www.powershellgallery.com/) using the MSI installer link).

You can also download this module from the Download Zip button on this page.  You'll need to extract the PSJira folder to your $PSModulePath (normally, this is at C:\Users\<username>Documents\WindowsPowerShell\Modules).

Finally, you can check the releases page here on GitHub for "stable" versions, but again, PSGallery will always have the latest (tested) version of the module.

## Usage

All the documentation for PSJira is on the [ReadTheDocs page](http://psjira.readthedocs.io).

For basic instructions to get up and running, check out the [Getting Started](http://psjira.readthedocs.io/en/latest/getting_started.html) page.

## Contributing

Want to contribute to PSJira?  Great! Start with the [Contributing](http://psjira.readthedocs.io/en/latest/contributing.html) page on the project documentation - it will explain how to work with PSJira's test and CI systems.

**Pull requests for PSJira are expected to pass all Pester tests before being merged.** More details can be found on the project documentation site.

## Contact

Feel free to comment on this project here on GitHub using the issues or discussion pages.  You can also check out [my blog](http://replicajunction.github.io/) or catch me on the [PowerShell subreddit](https://www.reddit.com/r/powershell).

*Note:* As with all community PowerShell modules and code, you use PSJira at your own risk.  I am not responsible if your JIRA instance causes a fire in your datacenter (literal or otherwise).
