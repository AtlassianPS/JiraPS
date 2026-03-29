# Public Function Tests

This directory contains unit tests for **public (exported) JiraPS functions**.

## Test Pattern

All tests in this directory follow the **CRUD function pattern** for public (exported) JiraPS functions.

### When to Use

Use this template for functions that:

- Make API calls to JIRA (Get-*, Set-*, New-*, Remove-*, Add-*, etc.)
- Accept user input and interact with external systems
- Require mocking of `Invoke-JiraMethod` and other internal functions

### Template Location

See [`.template.ps1`](.template.ps1) for the standard test structure.

### Reference Example

See [`Add-JiraFilterPermission.Unit.Tests.ps1`](Add-JiraFilterPermission.Unit.Tests.ps1) for a complete, working example.

## Test Structure

Public function tests are organized into three main sections:

### 1. Signature Tests

Verify function parameters, types, default values, and mandatory status to ensure the function interface remains stable.

### 2. Behavior Tests

Test the actual functionality including:

- Input resolution (converting strings to objects)
- API calls (verifying `Invoke-JiraMethod` is called correctly)
- Return values (checking converter functions are invoked)
- All code paths and branches

### 3. Input Validation Tests

Test parameter sets and input handling:

- Negative cases (invalid inputs with expected error messages)
- Positive cases (valid inputs processed correctly)
- Pipeline support
- Multiple item processing

## Mock Debugging

To debug mock parameter values, uncomment this line in the test's `BeforeAll` block:

```powershell
$VerbosePreference = 'Continue'
```

Then mocks using `Write-MockDebugInfo` will display their parameter values during test execution.

## Key Differences from Private Tests

Unlike converter tests in `Tests/Functions/Private/`:

- ✅ Require extensive mocking of API calls
- ✅ Test parameter signatures and validation
- ✅ Focus on error handling and edge cases
- ✅ Test interaction with external systems
