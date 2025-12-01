# Pester v4 to v5 Migration Status

## Overview

This document tracks the progress of migrating JiraPS test suite from Pester v4 to v5.

**Total Test Files**: 87  
**Migrated to v5**: 27 (31%)  
**Remaining v4**: 60 (69%)

## Phase 1: Simple Converter/Format Tests ✅ COMPLETE

**Status**: ✅ Completed  
**Date**: 2025-12-01  
**Files Migrated**: 27

### Files Successfully Migrated

#### ConvertFrom Tests (2 files)
- ✅ ConvertFrom-Json.Unit.Tests.ps1
- ✅ ConvertFrom-URLEncoded.Unit.Tests.ps1

#### ConvertTo Tests (24 files)
- ✅ ConvertTo-JiraAttachment.Unit.Tests.ps1
- ✅ ConvertTo-JiraComment.Unit.Tests.ps1
- ✅ ConvertTo-JiraComponent.Unit.Tests.ps1
- ✅ ConvertTo-JiraCreateMetaField.Unit.Tests.ps1
- ✅ ConvertTo-JiraEditMetaField.Unit.Tests.ps1
- ✅ ConvertTo-JiraField.Unit.Tests.ps1
- ✅ ConvertTo-JiraFilter.Unit.Tests.ps1
- ✅ ConvertTo-JiraFilterPermission.Unit.Tests.ps1
- ✅ ConvertTo-JiraGroup.Unit.Tests.ps1
- ✅ ConvertTo-JiraIssueLink.Unit.Tests.ps1
- ✅ ConvertTo-JiraIssueLinkType.Unit.Tests.ps1
- ✅ ConvertTo-JiraIssueType.Unit.Tests.ps1
- ✅ ConvertTo-JiraLink.Unit.Tests.ps1
- ✅ ConvertTo-JiraPriority.Unit.Tests.ps1
- ✅ ConvertTo-JiraProject.Unit.Tests.ps1
- ✅ ConvertTo-JiraProjectRole.Unit.Tests.ps1
- ✅ ConvertTo-JiraServerInfo.Unit.Tests.ps1
- ✅ ConvertTo-JiraSession.Unit.Tests.ps1
- ✅ ConvertTo-JiraStatus.Unit.Tests.ps1
- ✅ ConvertTo-JiraTransition.Unit.Tests.ps1
- ✅ ConvertTo-JiraUser.Unit.Tests.ps1
- ✅ ConvertTo-JiraVersion.Unit.Tests.ps1
- ✅ ConvertTo-JiraWorklogitem.Unit.Tests.ps1
- ✅ ConvertTo-URLEncoded.Unit.Tests.ps1

#### Format Tests (1 file)
- ✅ Format-Jira.Unit.Tests.ps1

### Infrastructure Created

1. **Migration Script**: `Tools/Migrate-Pester4To5.ps1`
   - Automated #requires statement updates
   - BuildHelpers removal and replacement
   - Should syntax conversion
   - Backup file creation

2. **Helper Module**: `Tests/Helpers/Resolve-ModuleSource.ps1`
   - Lightweight replacement for BuildHelpers
   - Resolves module path for testing
   - Works with both source and Release builds

3. **Updated Files**:
   - `Tests/Shared.ps1` - Updated to Pester v5 syntax
   - `Tools/build.requirements.psd1` - Changed Pester from 4.6.0 to 5.7.1
   - `.gitignore` - Added *.bak exclusion

### Migration Patterns Used

#### #requires Statement
```powershell
# Before (v4)
#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

# After (v5)
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }
```

#### Module Loading
```powershell
# Before (v4 with BuildHelpers)
BeforeAll {
    Remove-Item -Path Env:\BH*
    $projectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    Import-Module BuildHelpers
    Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -Path $projectRoot
    Import-Module $env:BHManifestToTest
}

# After (v5 with lightweight helper)
BeforeAll {
    . "$PSScriptRoot/../../Tests/Helpers/Resolve-ModuleSource.ps1"
    $moduleToTest = Resolve-ModuleSource
    Import-Module $moduleToTest -Force
}
```

#### Should Syntax
```powershell
# Before (v4)
$result | Should Be $expected
$result | Should Not BeNullOrEmpty
$result | Should BeNullOrEmpty
{ SomeCommand } | Should Throw

# After (v5)
$result | Should -Be $expected
$result | Should -Not -BeNullOrEmpty
$result | Should -BeNullOrEmpty
{ SomeCommand } | Should -Throw
```

## Phase 2: Critical Core Tests ⏳ PENDING

**Status**: ⏳ Not Started  
**Files**: 2

### Priority Order
1. ⏳ Invoke-JiraMethod.Unit.Tests.ps1 (690 lines) - **CRITICAL FIRST**
2. ⏳ ConvertTo-JiraIssue.Unit.Tests.ps1 (972 lines)

**Note**: These files are complex and require manual migration with careful testing.

## Phase 3: Remaining Tests ⏳ PENDING

**Status**: ⏳ Not Started  
**Files**: ~58

### Categories to Migrate
- Get-* functions (~20 files)
- Set-* functions (~8 files)
- New-* functions (~10 files)
- Remove-* functions (~5 files)
- Add-* functions (~5 files)
- Other utility functions (~10 files)

## Migration Checklist

### For Each Test File:
- [ ] Update #requires statement to Pester 5.7
- [ ] Remove BuildHelpers dependency
- [ ] Replace BeforeAll/AfterAll module loading
- [ ] Convert all Should syntax to use dashes
- [ ] Verify InModuleScope usage
- [ ] Check for BeforeEach/AfterEach that need to remain (session state)
- [ ] Create backup (.bak) file
- [ ] Test manually if complex

### Validation:
- [ ] All #requires updated
- [ ] No BuildHelpers references
- [ ] All "Should Be/Not" converted to "Should -Be/-Not"
- [ ] Module loading uses Resolve-ModuleSource helper
- [ ] Tests can discover and run (syntax valid)

## Notes

- **Backup Files**: All migration creates .bak files (excluded from git)
- **Automation**: Use `Tools/Migrate-Pester4To5.ps1` for simple files
- **Manual Review**: Complex files need manual migration
- **Assert-MockCalled**: Keep for now (deprecated but works in v5)
- **MaximumVersion**: Using 5.999 to avoid v6 breaking changes

## References

- [Pester v5 Migration Guide](https://pester.dev/docs/migrations/v3-to-v4)
- Original Plan: See problem statement in PR description
- Migration Script: `Tools/Migrate-Pester4To5.ps1`
