# Contributing to JiraPS

For contribution guidelines, see **[Contributing to AtlassianPS](https://atlassianps.org/docs/Contributing/)**.

## PowerShell style

Follow the [compact conditional block rules](.github/ai-context/powershell-rules.md#compact-conditional-blocks) for branch layout and examples.

## Object model reference

The [v3 object model reference](.github/ai-context/v3-object-contracts.md) maps domain types to converters, command parameters and tests.
It also records transformation decisions and related implementation work for contributors.

## Testing

For detailed information about writing and debugging tests, see the **[Testing Guide](Tests/README.md)**.

Key highlights:

- JiraPS uses **Pester 6.2.0 through 6.x** for unit testing
- All tests follow a consistent structure with Context blocks
- **Test organization**: Tests mirror the module structure
  - `Tests/Functions/Public/` - Public CRUD functions
  - `Tests/Functions/Private/` - Private converter functions
- **Mock debugging**: Uncomment `$VerbosePreference = 'Continue'` in BeforeAll to see mock parameter values
- **Templates**: Use [`.template.ps1`](Tests/Functions/Public/.template.ps1) in the appropriate directory as a starting point

### Creating new tests

When adding tests for a new function:

1. **Public functions** (Get-*, Set-*, New-*, etc.): Create in `Tests/Functions/Public/`
   - Use [`Tests/Functions/Public/.template.ps1`](Tests/Functions/Public/.template.ps1)
   - See [`Add-JiraFilterPermission.Unit.Tests.ps1`](Tests/Functions/Public/Add-JiraFilterPermission.Unit.Tests.ps1) for reference

2. **Private converter functions** (ConvertTo-*, ConvertFrom-*): Create in `Tests/Functions/Private/`
   - Use [`Tests/Functions/Private/.template.ps1`](Tests/Functions/Private/.template.ps1)
   - See [`ConvertTo-JiraAttachment.Unit.Tests.ps1`](Tests/Functions/Private/ConvertTo-JiraAttachment.Unit.Tests.ps1) for reference

## Quick start

Clone your fork and create a branch.
Replace `YOUR-USERNAME` with your GitHub username.

Before changing the code:

```powershell
git clone https://github.com/YOUR-USERNAME/JiraPS.git
cd JiraPS
git checkout -b my-feature
code .
```

After making and validating your changes:

```powershell
git add .
git commit -m 'Describe the change'
git push
```

[Create a pull request](https://help.github.com/articles/creating-a-pull-request/).
