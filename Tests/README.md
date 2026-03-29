# JiraPS Testing Guide

This guide explains how to write, run, and debug tests for JiraPS.

## Table of Contents

- [Test Structure](#test-structure)
- [Test Templates](#test-templates)
- [Running Tests](#running-tests)
- [Writing Tests](#writing-tests)
- [Debugging Mocks](#debugging-mocks)
- [Best Practices](#best-practices)

## Test Structure

JiraPS uses [Pester v5.7+](https://pester.dev/) for unit testing. All test files follow one of two standardized templates based on the function type being tested.

### Directory Organization

Tests are organized to mirror the module structure:

- **`Tests/Functions/Public/`** - Tests for public (exported) functions that make API calls
  - CRUD pattern for Get/Set/Remove/New/Add functions
  - See [`Public/README.md`](Functions/Public/README.md) for details
  - Example: [`Add-JiraFilterPermission.Unit.Tests.ps1`](Functions/Public/Add-JiraFilterPermission.Unit.Tests.ps1)

- **`Tests/Functions/Private/`** - Tests for private (internal) converter/formatter functions
  - Converter pattern for ConvertTo-*/ConvertFrom-* functions
  - See [`Private/README.md`](Functions/Private/README.md) for details
  - Example: [`ConvertTo-JiraAttachment.Unit.Tests.ps1`](Functions/Private/ConvertTo-JiraAttachment.Unit.Tests.ps1)

### Key Structure Elements

- **BeforeDiscovery**: Loads the module before test discovery. Variables need `$script:` prefix.
- **InModuleScope**: Required wrapper to access module internals. Must be top-level.
- **Describe Blocks**: Organize tests by category (Signature, Behavior, Input Validation).
- **Context Blocks**: Group related tests within a Describe block.
- **BeforeAll**: Set up test data and mocks. Variables need `$script:` prefix.

## Test Templates

JiraPS uses two primary test templates based on function type:

### CRUD Functions (Get/Set/Remove/New/Add)

**Location**: `Tests/Functions/Public/`

**Template File**: [`Tests/Functions/Public/.template.ps1`](Functions/Public/.template.ps1)

**Reference File**: [`Tests/Functions/Public/Add-JiraFilterPermission.Unit.Tests.ps1`](Functions/Public/Add-JiraFilterPermission.Unit.Tests.ps1)

**Use For**: Functions that make API calls - Get-*, Set-*, Remove-*, New-*, Add-* functions

**Structure**:

```powershell
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Add-JiraFilterPermission" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = "https://jira.example.com"
            # Test data and variables
            #endregion

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
                # Mock implementation
            }
            #endregion
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name $ThisTest
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(...) {
                    $command | Should -HaveParameter $parameter
                }
            }

            Context "Mandatory Parameters" {
                It "parameter '<parameter>' is mandatory" -TestCases @(...) {
                    $command | Should -HaveParameter $parameter -Mandatory
                }
            }
        }

        Describe "Behavior" {
            Context "Feature Description" {
                It "performs expected action" {
                    # Test implementation
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Negative Cases" {
                It "rejects invalid type '<description>'" -TestCases @(...) {
                    { ... } | Should -Throw -ExpectedMessage "*Filter*"
                }
            }

            Context "Type Validation - Positive Cases" {
                It "accepts valid input" {
                    { ... } | Should -Not -Throw
                }
            }
        }
    }
}
```

**Key Features**:

- Mock API calls with `Write-MockDebugInfo` for debugging
- Separate Describe blocks for Signature, Behavior, and Input Validation
- Positive/Negative test separation
- Error message validation with `-ExpectedMessage`

### Converter Functions (ConvertTo-*/ConvertFrom-*)

**Location**: `Tests/Functions/Private/`

**Template File**: [`Tests/Functions/Private/.template.ps1`](Functions/Private/.template.ps1)

**Reference File**: [`Tests/Functions/Private/ConvertTo-JiraAttachment.Unit.Tests.ps1`](Functions/Private/ConvertTo-JiraAttachment.Unit.Tests.ps1)

**Use For**: Functions that transform JSON to PowerShell objects - ConvertTo-*, ConvertFrom-* functions

**Structure**:

```powershell
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraAttachment" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'

            # Sample JSON fixture (can be large - keep it organized)
            $script:sampleJson = @"
{
    "id": "123",
    "name": "Example",
    "created": "2025-01-01T00:00:00.000Z"
}
"@

            $script:sampleObject = ConvertFrom-Json -InputObject $sampleJson
            #endregion

            #region Mocks
            # Converter functions typically don't need mocks
            #endregion
        }

        Describe "Behavior" {
            Context "Object Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-YourType -InputObject $sampleObject
                }

                It "creates a PSObject out of JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                }

                It "adds the custom type name 'JiraPS.YourType'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'JiraPS.YourType'
                }
            }

            Context "Property Mapping" {
                BeforeAll {
                    $script:result = ConvertTo-YourType -InputObject $sampleObject
                }

                It "defines the 'Id' property with correct value" {
                    $result.Id | Should -Be "123"
                }

                It "defines required properties" {
                    $result.Name | Should -Not -BeNullOrEmpty
                }
            }

            Context "Type Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-YourType -InputObject $sampleObject
                }

                It "converts 'created' field to DateTime object" {
                    $result.created | Should -Not -BeNullOrEmpty
                    $result.created | Should -BeOfType [System.DateTime]
                }

                It "converts nested objects to proper types" {
                    $result.author.PSObject.TypeNames[0] | Should -Be 'JiraPS.User'
                }
            }

            Context "Pipeline Support" {
                It "accepts input from pipeline" {
                    $result = $sampleObject | ConvertTo-YourType
                    $result | Should -Not -BeNullOrEmpty
                }

                It "handles array input" {
                    $multipleObjects = @($sampleObject, $sampleObject)
                    $result = $multipleObjects | ConvertTo-YourType
                    @($result).Count | Should -Be 2
                }
            }
        }
    }
}
```

**Key Features**:

- No mocks needed typically (pure transformation functions)
- Large JSON fixtures kept organized in `#region Definitions`
- Focus on type conversion and property mapping
- Organized Context blocks:
  - **Object Conversion**: Basic transformation and type name tests
  - **Property Mapping**: Field presence and values
  - **Type Conversion**: DateTime, nested objects, type checking
  - **Pipeline Support**: Pipeline behavior and array handling
- Use `BeforeAll` in contexts to avoid redundant conversions

### Template Comparison

| Aspect         | Public CRUD Functions                 | Private Converter Functions                                            |
| -------------- | ------------------------------------- | ---------------------------------------------------------------------- |
| **Mocks**      | Required (API calls)                  | Usually not needed                                                     |
| **Focus**      | API interaction                       | Data transformation                                                    |
| **Contexts**   | Signature, Behavior, Input Validation | Object Conversion, Property Mapping, Type Conversion, Pipeline Support |
| **Test Data**  | Minimal (IDs, strings)                | Large JSON fixtures                                                    |
| **Complexity** | Error handling, edge cases            | Type checking, nested objects                                          |

## Test Helpers (TestTools.ps1)

The `Tests/Helpers/TestTools.ps1` module provides reusable functions for test setup:

### Functions

**`Initialize-TestEnvironment`**

- Cleans up previously loaded JiraPS modules to ensure clean test state
- Must be called in `BeforeDiscovery` block before importing the module
- No return value; works via side effects

**`Resolve-ModuleSource`**

- Returns the path to the JiraPS module manifest (`.psd1`)
- Automatically detects source vs. Release build
- Store result in `$script:moduleToTest`

**`Resolve-ProjectRoot`**

- Returns the path to the project root directory
- Used by `Resolve-ModuleSource` internally
- Can be used in project-level tests (Build.Tests.ps1, etc.)

**`Write-MockDebugInfo`**

- Displays mock call information when `$VerbosePreference = 'Continue'`
- Call at the start of mock script blocks
- Parameters: `FunctionName` (string), `Params` (string array of parameter names)

### Usage Pattern

```powershell
BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment                    # Clean up modules
    $script:moduleToTest = Resolve-ModuleSource  # Get module path

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "YourFunction" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment to debug mocks

            Mock Get-JiraFilter -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraFilter' 'Id'  # Shows: Id = 123
                # mock logic
            }
        }
    }
}
```

## Running Tests

### Run All Tests

```powershell
# From repository root
Invoke-Build -Task Test
```

### Run Specific Test File

```powershell
Invoke-Pester ./Tests/Functions/Get-JiraIssue.Unit.Tests.ps1
```

### Run with Detailed Output

```powershell
Invoke-Pester ./Tests/Functions/Get-JiraIssue.Unit.Tests.ps1 -Output Detailed
```

### Run Tests by Tag

```powershell
Invoke-Pester -Path ./Tests -Tag Unit
```

## Writing Tests

### Test Naming Convention

- Test files: `FunctionName.Unit.Tests.ps1`
- Describe blocks: Use function name
- It blocks: Descriptive, starting with verb (e.g., "accepts valid filter object")

### Parameterized Tests

Use `-TestCases` for testing multiple scenarios:

```powershell
It "rejects invalid type '<description>'" -TestCases @(
    @{ description = "string"; value = "invalid" }
    @{ description = "number"; value = 123 }
    @{ description = "null"; value = $null }
) -Test {
    param($value)
    { Your-Function -Parameter $value } | Should -Throw -ExpectedMessage "*expected*"
}
```

### Error Testing

Always validate error messages for robust testing:

```powershell
Context "Type Validation - Negative Cases" {
    It "rejects invalid input with meaningful error" {
        { Your-Function -Parameter "bad" } | Should -Throw -ExpectedMessage "*Filter*"
    }
}
```

### Mocking

Mock external dependencies in `BeforeAll`:

```powershell
Mock Invoke-JiraMethod -ModuleName JiraPS {
    Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
    ConvertFrom-Json @'
    {
        "id": "123",
        "name": "Test"
    }
'@
}
```

## Debugging Mocks

### Using Write-MockDebugInfo Helper

The `Write-MockDebugInfo.ps1` helper provides easy mock debugging through verbose output.

#### Enable Debug Output

In your test file's `BeforeAll` block, uncomment the debug line:

```powershell
BeforeAll {
    . "$PSScriptRoot/../Helpers/Write-MockDebugInfo.ps1"

    # Uncomment to enable mock debug output:
    $VerbosePreference = 'Continue'  # <-- Uncomment this line

    # ... rest of BeforeAll
}
```

#### Add Debug Calls to Mocks

In your mock definitions, call `Write-MockDebugInfo` with the function name and parameter names:

```powershell
Mock Invoke-JiraMethod -ModuleName JiraPS {
    Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
    # ... mock implementation
}

Mock Get-JiraFilter -ModuleName JiraPS {
    Write-MockDebugInfo 'Get-JiraFilter' 'Id', 'Name'
    # ... mock implementation
}
```

#### Run Tests and View Output

```powershell
Invoke-Pester ./Tests/Functions/Your-Test.Unit.Tests.ps1 -Output Detailed
```

**Important**: The `-Verbose` parameter on `Invoke-Pester` does NOT enable mock debug output. It only shows Pester's internal verbose messages. The debug output will appear automatically once you set `$VerbosePreference = 'Continue'` in the test file's BeforeAll block.

You'll see output like:

```console
🔷 Mock: Invoke-JiraMethod
  [Method] = "GET"
  [Uri] = "https://jira.example.com/rest/api/2/issue/TEST-123"
  [Body] = <null>

🔷 Mock: Get-JiraFilter
  [Id] = 12345
  [Name] = <null>
```

#### Debug Output Features

- **Color coding**: Function names in Cyan, values in Yellow, nulls in DarkGray
- **Type awareness**: Arrays show item count and contents (up to 5 items)
- **Hashtable display**: Shows key/value pairs
- **String truncation**: Long strings truncated to 97 characters with "..."
- **Null indication**: Shows `<null>` for null/empty values

#### Disable Debug Output

When finished debugging, re-comment the line:

```powershell
# $VerbosePreference = 'Continue'
```

### Why Doesn't -Verbose Work?

The `-Verbose` parameter on `Invoke-Pester` only affects Pester's own internal logging, not the test script's `$VerbosePreference`. Due to how Pester v5 isolates test execution contexts, command-line parameters don't propagate into the test script scope. This is why you must set `$VerbosePreference` directly inside the test file.

### Alternative: Manual Debugging

If you need interactive debugging, use breakpoints:

```powershell
Mock Invoke-JiraMethod -ModuleName JiraPS {
    $Method | Set-PSBreakpoint  # Set breakpoint
    # ... mock implementation
}
```

Then run in VS Code or with `pwsh -Debug`.

## Best Practices

### Test Organization

1. **Group by purpose**: Use Context blocks to separate positive/negative tests
2. **Clear naming**: Describe what's being tested, not how
3. **One assertion per test**: Makes failures easy to identify
4. **Test data in regions**: Use `#region Definitions` and `#region Mocks`

### Code Quality

1. **Use validation attributes**: `[ValidateNotNullOrEmpty()]`, `[ValidatePattern()]`
2. **Test pipeline support**: Use `-TestCases` with pipeline input
3. **Verify mock calls**: Use `Should -Invoke` to verify mock behavior
4. **Error messages**: Always include `-ExpectedMessage` in error tests

### Performance

1. **Mock external calls**: Never make real API calls in unit tests
2. **Minimize setup**: Use `BeforeAll` instead of `BeforeEach` where possible
3. **Parameterized tests**: Reduce duplicate test code

### Maintainability

1. **Follow template**: Use `Add-JiraFilterPermission.Unit.Tests.ps1` as reference
2. **American English**: Use "Behavior" not "Behaviour"
3. **Consistent styling**: Follow existing patterns in the codebase
4. **Document complex tests**: Add comments for non-obvious test logic

## Example Test File

See [`Tests/Functions/Add-JiraFilterPermission.Unit.Tests.ps1`](Functions/Add-JiraFilterPermission.Unit.Tests.ps1) for a complete, well-structured test file that demonstrates all best practices.

## Troubleshooting

### Tests Not Running

- Ensure Pester 5.7+ is installed: `Install-Module Pester -MinimumVersion 5.7 -Force`
- Check for syntax errors in test file
- Verify module imports correctly in BeforeDiscovery

### Mocks Not Working

- Confirm `InModuleScope JiraPS` wraps Describe block
- Check `-ModuleName JiraPS` is specified in Mock
- Verify function is exported from module (check `JiraPS.psd1`)

### Debug Output Not Showing

- Verify `$VerbosePreference = 'Continue'` is uncommented in BeforeAll
- Check `Write-MockDebugInfo.ps1` is loaded before mocks are defined
- Ensure `Write-MockDebugInfo` is called inside mock definition

### Variable Scope Issues

- Use `$script:` prefix in BeforeDiscovery and BeforeAll
- Use plain variable names in Describe blocks
- Reference `$script:variableName` in It blocks if needed

## Resources

- [Pester Documentation](https://pester.dev/docs/quick-start)
- [JiraPS Documentation](https://atlassianps.org/docs/JiraPS/)
- [AtlassianPS Contributing Guide](https://atlassianps.org/docs/Contributing/)
