# JiraPS Integration Tests

This directory contains integration tests that run against a live Jira Cloud instance.

## Overview

Integration tests verify that JiraPS functions work correctly with actual Jira APIs. Unlike unit tests that mock API calls, integration tests make real HTTP requests and validate real responses.

## Prerequisites

1. **Jira Cloud Instance**: You need access to a Jira Cloud instance for testing
2. **API Token**: Generate an API token from [Atlassian Account Settings](https://id.atlassian.com/manage-profile/security/api-tokens)
3. **Test Project**: A dedicated project for running tests (recommended)
4. **Test Fixtures**: Pre-existing test data (issue, user, group, etc.)

## Setup

### 1. Create Environment File

Copy the example environment file and configure your credentials:

```powershell
Copy-Item .env.example .env
```

Edit `.env` with your Jira Cloud connection details:

```
JIRA_CLOUD_URL=https://your-instance.atlassian.net/
JIRA_CLOUD_USERNAME=your-email@example.com
JIRA_CLOUD_PASSWORD=your-api-token

JIRA_TEST_PROJECT=TV
JIRA_TEST_ISSUE=TV-1
JIRA_TEST_USER=557058:12345678-...
JIRA_TEST_GROUP=jira-users
```

### 2. Verify Test Fixtures

Ensure the following exist in your Jira instance:

| Fixture | Description |
|---------|-------------|
| Test Project | A project dedicated to testing (e.g., `TV`) |
| Test Issue | A permanent issue for read tests (e.g., `TV-1`) |
| Test User | Your account ID for user tests |
| Test Group | A group for membership tests |

### 3. Test the Connection

Run a quick verification:

```powershell
. ./Tests/Helpers/IntegrationTestTools.ps1

$env = Initialize-IntegrationEnvironment
$session = Connect-JiraTestServer -Environment $env

Get-JiraServerInformation
```

## Running Integration Tests

Integration tests can run directly against source code without building. This is faster and simpler for development.

### Using Invoke-Build (Recommended)

The easiest way to run integration tests is through the build system:

```powershell
# Run all integration tests in parallel
Invoke-Build -Task TestIntegration

# Run smoke tests only
Invoke-Build -Task TestIntegration -Tag 'Smoke'

# Increase parallelism (default is 4)
Invoke-Build -Task TestIntegration -ThrottleLimit 8

# More verbose output
Invoke-Build -Task TestIntegration -PesterVerbosity Detailed
```

This runs 4 test files concurrently by default, reducing total time from ~10 minutes to ~3.5 minutes.

### Using the Script Directly

For more control, use the parallel runner script directly:

```powershell
./Tests/Invoke-ParallelPester.ps1 -ThrottleLimit 4
./Tests/Invoke-ParallelPester.ps1 -Tag 'Smoke' -Output Detailed
```

### Sequential Execution

```powershell
$config = New-PesterConfiguration
$config.Run.Path = './Tests/Integration/'
$config.Filter.Tag = @('Integration')
$config.Output.Verbosity = 'Detailed'
Invoke-Pester -Configuration $config
```

**Smoke tests cover:**
- Authentication (New-JiraSession, Get-JiraSession)
- Server connectivity (Get-JiraServerInformation)
- Issue retrieval (Get-JiraIssue)
- Issue creation (New-JiraIssue)
- JQL search (Get-JiraIssue -Query)

Use smoke tests for:
- Quick pre-commit validation
- CI pipeline health checks
- Verifying environment setup

### Run Specific Test File

```powershell
Invoke-Pester ./Tests/Integration/Get-JiraIssue.Integration.Tests.ps1 -Output Detailed
```

### Using Invoke-Build (With Build)

If you need to test against the built module:

```powershell
Invoke-Build -Task Build
Invoke-Build -Task Test -Tag 'Integration'
```

## Parallel Test Runner

The `Invoke-ParallelPester.ps1` script uses PowerShell 7's `ForEach-Object -Parallel` to run test files concurrently.

### Usage

```powershell
# Run all integration tests with 4 concurrent files
./Tests/Invoke-ParallelPester.ps1 -ThrottleLimit 4

# Run only smoke tests
./Tests/Invoke-ParallelPester.ps1 -Tag 'Smoke' -ThrottleLimit 6

# Run specific files
./Tests/Invoke-ParallelPester.ps1 -Path @(
    './Tests/Integration/Authentication.Integration.Tests.ps1',
    './Tests/Integration/Get-JiraIssue.Integration.Tests.ps1'
)

# Minimal output
./Tests/Invoke-ParallelPester.ps1 -Output Normal
```

### Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-Path` | Directory or file paths | `./Tests/Integration/` |
| `-ThrottleLimit` | Max concurrent tests | 4 |
| `-Tag` | Filter by tag | (none) |
| `-ExcludeTag` | Exclude by tag | (none) |
| `-Output` | Verbosity level | Normal |

### Performance

| Mode | Time | Notes |
|------|------|-------|
| Sequential | ~10+ min | Single file at a time |
| Parallel (4) | ~3.5 min | 3x faster |
| Parallel (6) | ~2.5 min | Diminishing returns |

**Note:** Requires PowerShell 7+ for `ForEach-Object -Parallel` support.

## Test Structure

Integration tests follow the same Pester v5 patterns as unit tests:

```powershell
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource
    Import-Module $script:moduleToTest -Force -ErrorAction Stop

    # Skip if environment not configured
    $script:Skip = Skip-IntegrationTest
}

InModuleScope JiraPS {
    Describe "Get-JiraIssue" -Tag 'Integration' -Skip:$Skip {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env
        }

        AfterAll {
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        Context "Issue Retrieval" {
            It "retrieves an issue by key" {
                $issue = Get-JiraIssue -Key $fixtures.TestIssue

                $issue | Should -Not -BeNullOrEmpty
                $issue.Key | Should -Be $fixtures.TestIssue
            }
        }
    }
}
```

## Helper Functions

The `IntegrationTestTools.ps1` module provides:

| Function | Description |
|----------|-------------|
| `Initialize-IntegrationEnvironment` | Loads `.env` and returns config object |
| `Connect-JiraTestServer` | Establishes authenticated session |
| `Get-TestFixture` | Returns hashtable of test fixture references |
| `Skip-IntegrationTest` | Returns `$true` if environment not configured |
| `New-TemporaryTestIssue` | Creates a temporary issue for write tests |
| `New-TestResourceName` | Generates prefixed name like `JiraPS-IntTest-Issue-20260412...` |
| `Get-TestResourcePrefix` | Returns the prefix used for test resources |
| `Remove-StaleTestResource` | Cleans up resources from failed test runs |

## Cleanup Strategy

Integration tests create real resources in Jira. Here's how we ensure cleanup happens even when tests fail:

### 1. Use Prefixed Names

All test resources use a discoverable prefix (`JiraPS-IntTest-`):

```powershell
$summary = New-TestResourceName -Type "Issue"
# Returns: "JiraPS-IntTest-Issue-20260412233045"
```

### 2. Track Created Resources

Use `ArrayList` (not arrays) initialized in `BeforeAll`:

```powershell
BeforeAll {
    # Initialize BEFORE any test might fail
    $script:createdIssues = [System.Collections.ArrayList]::new()
}

It "creates an issue" {
    $issue = New-JiraIssue ...
    $null = $script:createdIssues.Add($issue.Key)  # $null suppresses index output
}
```

### 3. Cleanup at START of Test Run

Remove stale resources from previous failed runs:

```powershell
BeforeAll {
    # This finds and deletes old JiraPS-IntTest-* resources
    Remove-StaleTestResource -Fixtures $fixtures
}
```

### 4. Resilient AfterAll Cleanup

Handle null/empty arrays gracefully:

```powershell
AfterAll {
    if ($script:createdIssues -and $script:createdIssues.Count -gt 0) {
        foreach ($key in $script:createdIssues) {
            try {
                Remove-JiraIssue -IssueId $key -Force -ErrorAction SilentlyContinue
            }
            catch { <# ignore cleanup failures #> }
        }
    }
}
```

### 5. Manual Cleanup (if needed)

If tests leave behind resources, clean them manually:

```powershell
# Find stale resources via JQL
Get-JiraIssue -Query "project = TV AND summary ~ 'JiraPS-IntTest-'"

# Or run cleanup helper
. ./Tests/Helpers/IntegrationTestTools.ps1
$env = Initialize-IntegrationEnvironment
Connect-JiraTestServer -Environment $env
Remove-StaleTestResource -MaxAge (New-TimeSpan -Minutes 5)
```

## Write Tests

For tests that create, update, or delete resources:

```powershell
Context "Write Operations" -Skip:($fixtures.ReadOnly) {
    BeforeAll {
        $script:tempIssue = New-TemporaryTestIssue -Summary "Test $(Get-Date -Format 'yyyyMMddHHmmss')"
    }

    AfterAll {
        if ($tempIssue) {
            Remove-JiraIssue -IssueId $tempIssue.Key -Force -ErrorAction SilentlyContinue
        }
    }

    It "updates an issue" {
        Set-JiraIssue -Issue $tempIssue.Key -Summary "Updated"
        # ...
    }
}
```

## CI/CD

Integration tests have a dedicated workflow (`.github/workflows/integration_tests.yml`) separate from the unit test workflow.

### Workflow Triggers

| Trigger | Smoke Tests | Full Integration Tests |
|---------|-------------|------------------------|
| Push to default branch | ✅ | ✅ |
| Pull Request | ✅ | ❌ (add `run-integration-tests` label) |
| Nightly (6 AM UTC) | ✅ | ✅ |
| Manual (`workflow_dispatch`) | ✅ | ✅ |

### Required Secrets

Configure these in your repository settings:

| Secret | Required | Description |
|--------|----------|-------------|
| `JIRA_CLOUD_URL` | ✅ | Jira Cloud instance URL |
| `JIRA_CLOUD_USERNAME` | ✅ | Email address |
| `JIRA_CLOUD_PASSWORD` | ✅ | API token |
| `JIRA_TEST_PROJECT` | ✅ | Project key (e.g., `TV`) |
| `JIRA_TEST_ISSUE` | ✅ | Existing issue key (e.g., `TV-1`) |
| `JIRA_TEST_USER` | ⚪ | Account ID for user tests |
| `JIRA_TEST_GROUP` | ⚪ | Group name for group tests |
| `JIRA_TEST_FILTER` | ⚪ | Filter ID for filter tests |
| `JIRA_TEST_VERSION` | ⚪ | Version name for version tests |

If secrets are not configured, integration tests are skipped automatically.

### Running Full Integration Tests on PRs

To run full integration tests on a pull request:

1. Add the label `run-integration-tests` to the PR
2. The integration workflow will run automatically
3. Remove the label after tests complete (optional)

### Workflow Features

- **No build required**: Tests run directly against source for speed
- **Parallel execution**: Uses `Invoke-Build -Task TestIntegration` with `ThrottleLimit=4`
- **Concurrency control**: Cancels in-progress runs for the same branch
- **Test summary**: Generates a summary in the GitHub Actions UI

## Troubleshooting

### Tests Skip with "Integration environment not configured"

1. Ensure `.env` file exists in project root
2. Check all required variables are set
3. Run `Initialize-IntegrationEnvironment` manually to see which variables are missing

### Authentication Errors

1. Verify API token is valid (not expired)
2. Check username is your email address (not username)
3. Ensure the URL includes trailing slash

### Permission Errors

1. Verify your account has access to the test project
2. Check group membership for group tests
3. Ensure you have permission to create/edit issues for write tests

## Adding New Tests

1. Copy `.template.ps1` to `<FunctionName>.Integration.Tests.ps1`
2. Update the function name in `Describe`
3. Add appropriate test contexts and assertions
4. Run the test locally before committing

See existing tests for examples of common patterns.
