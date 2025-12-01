# Contributing to JiraPS

Happy to see you are interested in helping.

We have a comprehensive documentation on how to contribute here: **[Contributing to AtlassianPS](https://atlassianps.org/docs/Contributing/)**.

## Testing

For detailed information about writing and debugging tests, see the **[Testing Guide](Tests/README.md)**.

Key highlights:

- JiraPS uses **Pester v5.7+** for unit testing
- All tests follow a consistent structure with Context blocks
- **Mock debugging**: Uncomment `$VerbosePreference = 'Continue'` in BeforeAll to see mock parameter values
- See `Tests/Functions/Add-JiraFilterPermission.Unit.Tests.ps1` for a reference template

## Quick Start

Here is the gist of it once you have forked the repository:

- before changing the code

```powershell
git clone https://github.com/<YOUR GITHUB USER>/JiraPS
cd JiraPS
git checkout -b <NAME FOR YOUR FEATURE>
code .
```

- after making the changes

```powershell
git add .
git commit -m "<A MESSAGE ABOUT THE CHANGES>"
git push
```

- [create a Pull Request](https://help.github.com/articles/creating-a-pull-request/)
