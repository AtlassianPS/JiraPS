# Private Function Tests

This directory contains unit tests for **private (internal) JiraPS functions**.

## Test Pattern

All tests in this directory follow the **converter function pattern** for private (internal) JiraPS functions.

### When to Use

Use this template for functions that:

- Transform data (ConvertTo-*, ConvertFrom-*)
- Parse JSON responses into PowerShell objects
- Perform pure data manipulation without external calls
- Format or encode/decode data

### Template Location

See [`.template.ps1`](.template.ps1) for the standard test structure.

### Reference Example

See [`ConvertTo-JiraAttachment.Unit.Tests.ps1`](ConvertTo-JiraAttachment.Unit.Tests.ps1) for a complete, working example.

## Test Structure

Converter function tests focus on a single `Describe "Behavior"` block with four contexts:

### 1. Object Conversion

Verify that:

- The function creates a valid PSObject
- The correct type name is added (e.g., `JiraPS.Attachment`)

### 2. Property Mapping

Test that:

- All expected properties are present
- Properties have correct values from the source data
- Both simple and nested properties are mapped correctly

Use data-driven tests with `-TestCases` for comprehensive property validation.

### 3. Type Conversion

Verify special type handling:

- DateTime fields are converted from ISO strings
- Nested objects are converted to proper custom types (e.g., `JiraPS.User`)
- Numeric values are properly typed

### 4. Pipeline Support

Test that:

- Function accepts input from pipeline
- Array inputs are handled correctly
- Multiple objects can be processed in a single call

## Key Characteristics

Converter tests typically:

- ❌ Don't require mocks (pure transformation)
- ✅ Use large JSON fixtures in `#region Definitions`
- ✅ Use `BeforeAll` in contexts to avoid redundant conversions
- ✅ Focus on data transformation accuracy
- ✅ Test type names and .NET types extensively

## Sample JSON Data

Keep your JSON fixtures organized:

```powershell
#region Definitions
$jiraServer = 'http://jiraserver.example.com'

$sampleJson = @"
{
    "id": "123",
    "name": "Test Resource",
    "created": "2025-01-01T00:00:00.000Z",
    "author": {
        "name": "JonDoe",
        "displayName": "Doe, Jon"
    }
}
"@

$script:sampleObject = ConvertFrom-Json -InputObject $sampleJson
#endregion Definitions
```

**Important**: Always remove personal/sensitive data from JSON fixtures.

## Key Differences from Public Tests

Unlike CRUD tests in `Tests/Functions/Public/`:

- ❌ No signature tests (private functions)
- ❌ Minimal or no mocking required
- ✅ Large, detailed JSON fixtures
- ✅ Focus on data transformation, not API interaction
- ✅ Simpler test structure (single Describe block)
