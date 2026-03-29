# Contributing to JiraPS

Happy to see you are interested in helping.

We have a comprehensive documentation on how to contribute here: **[Contributing to AtlassianPS](https://atlassianps.org/docs/Contributing/)**.

## Testing

For detailed information about writing and debugging tests, see the **[Testing Guide](Tests/README.md)**.

Key highlights:

- JiraPS uses **Pester v5.7+** for unit testing
- All tests follow a consistent structure with Context blocks
- **Test organization**: Tests mirror the module structure
  - `Tests/Functions/Public/` - Public CRUD functions
  - `Tests/Functions/Private/` - Private converter functions
- **Mock debugging**: Uncomment `$VerbosePreference = 'Continue'` in BeforeAll to see mock parameter values
- **Templates**: Use [`.template.ps1`](Tests/Functions/Public/.template.ps1) in the appropriate directory as a starting point

### Creating New Tests

When adding tests for a new function:

1. **Public functions** (Get-*, Set-*, New-*, etc.): Create in `Tests/Functions/Public/`
   - Use [`Tests/Functions/Public/.template.ps1`](Tests/Functions/Public/.template.ps1)
   - See [`Add-JiraFilterPermission.Unit.Tests.ps1`](Tests/Functions/Public/Add-JiraFilterPermission.Unit.Tests.ps1) for reference

2. **Private converter functions** (ConvertTo-*, ConvertFrom-*): Create in `Tests/Functions/Private/`
   - Use [`Tests/Functions/Private/.template.ps1`](Tests/Functions/Private/.template.ps1)
   - See [`ConvertTo-JiraAttachment.Unit.Tests.ps1`](Tests/Functions/Private/ConvertTo-JiraAttachment.Unit.Tests.ps1) for reference

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
