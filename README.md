# PSJira

[![Build status](https://ci.appveyor.com/api/projects/status/rog7nhvpfu58xrxu?svg=true)](https://ci.appveyor.com/project/JoshuaT/psjira)

PSJira is a Windows PowerShell module to interact with [Atlassian Jira](https://www.atlassian.com/software/jira) via a REST API, while maintaining a consistent PowerShell look and feel.

## Requirements

This module has a hard dependency on PowerShell 3.0.  I have no plans to release a version compatible with PowerShell 2, as I rely heavily on several cmdlets and syntax features added in version 3.0.

## Getting Started

1. Download this module, either from the Download Zip" button on the right, or by directly cloning in Git.
2. Extract the module to somewhere in your $PSModulePath.  Normally, this is at C:\Users\<username>\Documents\WindowsPowerShell\Modules.
3. Define your JIRA server URL.  You will only need to do this once:
```powershell
Set-JiraConfigServer "https://jira.example.com"
```

That's it!  You're now ready to use PSJira.

## Usage

See the project Wiki for detailed use information.

## Contact

Feel free to comment on this project here on GitHub using the issues or discussion pages.  You can also check out [my blog](http://replicajunction.github.io/) or catch me on the [PowerShell subreddit](https://www.reddit.com/r/powershell).