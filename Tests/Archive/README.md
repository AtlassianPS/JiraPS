# Archived Test Files

This directory contains archived test files that are kept for historical reference only.

## Contents

### JiraPS.Integration.Tests.legacy.ps1

**Status**: Archived, not executed

This file contains the original integration tests from before the Pester v5 migration. It uses:
- Pester 4 syntax (`Should Be` instead of `Should -Be`)
- Legacy helper functions from `Shared.ps1`
- Old environment variable naming (`JiraURI`, `JiraUser`, `JiraPass`)

**Do not run these tests.** They are preserved only for reference when writing new integration tests.

The new integration tests are located in `Tests/Integration/` and follow the Pester v5 patterns used by the unit tests.

## Migration Notes

When migrating patterns from these legacy tests:

1. Update Pester syntax: `Should Be` → `Should -Be`
2. Replace `defProp`, `hasProp`, `checkType` with direct assertions
3. Use `IntegrationTestTools.ps1` helpers instead of `Shared.ps1`
4. Update environment variables to new naming convention
5. Add proper `-Tag 'Integration'` to Describe blocks
