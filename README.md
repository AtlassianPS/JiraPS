# [JiraPS](https://JiraPS.github.io/)

[![Build status](https://ci.appveyor.com/api/projects/status/utpel25via67xw3b?svg=true)](https://ci.appveyor.com/project/JoshuaT/psjira)
[![Documentation Status](https://readthedocs.org/projects/JiraPS/badge/?version=latest)](http://JiraPS.readthedocs.io/en/latest/?badge=latest)

JiraPS is a Windows PowerShell module to interact with [Atlassian JIRA](https://www.atlassian.com/software/jira) via a REST API, while maintaining a consistent PowerShell look and feel.

Join the conversation on [![SlackLogo][] AtlassianPS.Slack.com](https://slofile.com/slack/atlassianps)

[SlackLogo]: assets/Slack_Mark_Web_28x28.png

---

## Documentation on ReadTheDocs

Documentation for JiraPS has moved to [ReadTheDocs.io](http://JiraPS.readthedocs.io). Check it out, and feel free to submit issues or PRs against the documentation as well!

---

## Requirements

This module has a hard dependency on PowerShell 3.0.  There are no plans to release a version compatible with PowerShell 2, as the module relies on several cmdlets and features added in version 3.0.

## Downloading

Due to the magic of continuous integration, the latest passing build of this project will always be on the PowerShell Gallery. If you have the Package Management module for PowerShell (which comes with PowerShell 5.0), you can install the latest build easily:

```powershell
Install-Module JiraPS
```

If you're using PowerShell 3 or 4, consider updating! If that's not an option, consider installing PackageManagement on PowerShell 3 or 4 (you can do so from the [PowerShell gallery](https://www.powershellgallery.com/) using the MSI installer link).

You can also download this module from the Download Zip button on this page.  You'll need to extract the JiraPS folder to your $PSModulePath (normally, this is at C:\Users\\<username>\\Documents\WindowsPowerShell\Modules).

Finally, you can check the releases page here on GitHub for "stable" versions, but again, PSGallery will always have the latest (tested) version of the module.

## Usage

All the documentation for JiraPS is on the [ReadTheDocs page](http://PSJira.readthedocs.io).

For basic instructions to get up and running, check out the [Getting Started](http://PSJira.readthedocs.io/en/latest/getting_started.html) page.

## Contributing

Want to contribute to JiraPS?  Great! Start with the [Contributing](http://PSJira.readthedocs.io/en/latest/contributing.html) page on the project documentation - it will explain how to work with JiraPS's test and CI systems.

**Pull requests for JiraPS are expected to pass all Pester tests before being merged.** More details can be found on the project documentation site.

## Contact

Join the conversation on [![SlackLogo][] AtlassianPS.Slack.com](https://slofile.com/slack/atlassianps)  
Or write an email to contact@atlassianps.org

*Note:* As with all community PowerShell modules and code, you use JiraPS at your own risk.  I am not responsible if your JIRA instance causes a fire in your datacenter (literal or otherwise).
