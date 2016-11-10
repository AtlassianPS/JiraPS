# NOTICE CURRENTLY NOT IN A FUNCTIONAL STATE!!!! 

# PSBitBucket

PSBitBucket is a Windows PowerShell module to interact with [Atlassian bitbucket](https://www.atlassian.com/software/bitbucket) via a REST API, while maintaining a consistent PowerShell look and feel.

---

## Project update: November 2016

---

## Requirements

This module has a hard dependency on PowerShell 3.0.  I have no plans to release a version compatible with PowerShell 2, as I rely heavily on several cmdlets and features added in version 3.0.

## Downloading

Due to the magic of continuous integration, the latest passing build of this project will always be on the PowerShell Gallery. If you have the Package Management module for PowerShell (which comes with PowerShell 5.0), you can install the latest build easily:

```powershell
Install-Module PSBitBucket
```

If you're using PowerShell 3 or 4, consider updating! If that's not an option, consider installing PackageManagement on PowerShell 3 or 4 (you can do so from the [PowerShell gallery](https://www.powershellgallery.com/) using the MSI installer link).

You can also download this module from the Download Zip button on this page.  You'll need to extract the PSBitBucket folder to your $PSModulePath (normally, this is at C:\Users\<username>Documents\WindowsPowerShell\Modules).

Finally, you can check the releases page here on GitHub for "stable" versions, but again, PSGallery will always have the latest (tested) version of the module.

## Getting Started

Before using PSBitBucket, you'll need to define your bitbucket server URL.  You will only need to do this once:

```powershell
Set-BitBucketConfigServer "https://bitbucket.example.com"
```

## Usage


## Planned features

## Contributing
Want to contribute to PSBitBucket?  Great! Here are a couple of notes regarding contributions:

* PSBitBucket relies heavily upon Pester testing to make sure that changes don't break each other.  Please respect the tests when coding against PSBitBucket.
* Pull requests are much more likely to be accepted if all tests pass.
* If you write a change that causes a test to fail, please explain why the change is appropriate.  Tests are code, just like the module itself, so it's very possbile that they need to be fixed as well.  Bonus points if you also write the fix for the test.
* If implementing a brand-new function or behavior, please write a test for it.
* Please respect the formatting style of the rest of the module code as well.  If in doubt, place braces on a new line.

Changes will be merged and released when the module passes all Pester tests, including the module style tests.

## Contact

Feel free to comment on this project here on GitHub using the issues or discussion pages.  You can also check out [my blog](http://beaudry.io) or catch me on [reddit](https://www.reddit.com/u/crossbeau).

*Note:* As with all community PowerShell modules and code, you use PSBitBucket at your own risk.  I am not responsible if your bitbucket instance causes a fire in your datacenter (literal or otherwise).
