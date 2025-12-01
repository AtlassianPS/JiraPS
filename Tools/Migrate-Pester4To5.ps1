<#
.SYNOPSIS
    Automated migration script to convert Pester v4 test files to v5 syntax.

.DESCRIPTION
    This script performs automated conversion of Pester v4 test files to v5 syntax:
    - Updates #requires statement from v4.4.0 to v5.7 with MaximumVersion 5.999
    - Converts Should syntax: "Should Be" → "Should -Be", "Should Not" → "Should -Not", etc.
    - Removes BuildHelpers dependency and replaces with lightweight helper pattern
    - Creates .bak backups before modifying files
    - Optionally validates converted files with Invoke-Pester

.PARAMETER Path
    Path to test file(s) to migrate. Supports wildcards.

.PARAMETER NoBackup
    Skip creating .bak backup files.

.PARAMETER Validate
    Run Invoke-Pester on converted files to validate syntax.

.EXAMPLE
    .\Migrate-Pester4To5.ps1 -Path Tests/Functions/ConvertTo-*.Unit.Tests.ps1

.EXAMPLE
    .\Migrate-Pester4To5.ps1 -Path Tests/Functions/ConvertTo-JiraAttachment.Unit.Tests.ps1 -Validate
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [string[]]$Path,

    [switch]$NoBackup,

    [switch]$Validate
)

begin {
    $ErrorActionPreference = 'Stop'
    
    function Write-MigrationLog {
        param(
            [string]$Message,
            [ValidateSet('Info', 'Success', 'Warning', 'Error')]
            [string]$Level = 'Info'
        )
        
        $color = switch ($Level) {
            'Info' { 'Cyan' }
            'Success' { 'Green' }
            'Warning' { 'Yellow' }
            'Error' { 'Red' }
        }
        
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }

    function Get-ResolvedPath {
        param([string]$Path)
        
        $resolvedPaths = @()
        foreach ($p in (Resolve-Path $Path -ErrorAction SilentlyContinue)) {
            if (Test-Path $p -PathType Leaf) {
                $resolvedPaths += $p
            }
        }
        return $resolvedPaths
    }
}

process {
    foreach ($pathPattern in $Path) {
        $files = Get-ResolvedPath -Path $pathPattern
        
        if (-not $files) {
            Write-MigrationLog "No files found matching: $pathPattern" -Level Warning
            continue
        }

        foreach ($file in $files) {
            Write-MigrationLog "Processing: $file" -Level Info
            
            # Create backup
            if (-not $NoBackup) {
                $bakPath = "$file.bak"
                if (Test-Path $bakPath) {
                    Write-MigrationLog "  Backup already exists, skipping: $bakPath" -Level Warning
                    continue
                }
                Copy-Item -Path $file -Destination $bakPath -Force
                Write-MigrationLog "  Created backup: $bakPath" -Level Info
            }

            # Read file content
            $content = Get-Content -Path $file -Raw
            $originalContent = $content

            # Step 1: Update #requires statement for Pester version
            Write-MigrationLog "  Updating #requires statement..." -Level Info
            $content = $content -replace '#requires -modules @\{ ModuleName = "Pester"; ModuleVersion = "4\.4\.0" \}', '#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }'
            
            # Step 2: Remove BuildHelpers #requires
            Write-MigrationLog "  Removing BuildHelpers dependency..." -Level Info
            $content = $content -replace '(?m)^#requires -modules BuildHelpers\r?\n', ''
            
            # Step 3: Replace BuildHelpers setup pattern with lightweight helper
            Write-MigrationLog "  Replacing BuildHelpers setup pattern..." -Level Info
            
            # Pattern to match the BuildHelpers BeforeAll block
            $buildHelpersPattern = @'
(?s)BeforeAll \{.*?Remove-Item -Path Env:\\BH\*.*?Set-BuildEnvironment.*?Import-Module \$env:BHManifestToTest.*?\}
'@
            
            $newBeforeAll = @'
BeforeAll {
        . "$PSScriptRoot/../../Tests/Helpers/Resolve-ModuleSource.ps1"
        $moduleToTest = Resolve-ModuleSource
        Import-Module $moduleToTest -Force
    }
'@
            
            # Only replace if it matches the BuildHelpers pattern
            if ($content -match $buildHelpersPattern) {
                $content = $content -replace $buildHelpersPattern, $newBeforeAll
            }
            
            # Step 4: Clean up AfterAll to remove BuildHelpers cleanup
            Write-MigrationLog "  Cleaning up AfterAll block..." -Level Info
            $afterAllPattern = @'
(?s)AfterAll \{.*?Remove-Module \$env:BHProjectName.*?Remove-Module BuildHelpers.*?Remove-Item -Path Env:\\BH\*.*?\}
'@
            
            $newAfterAll = @'
AfterAll {
        Remove-Module JiraPS -ErrorAction SilentlyContinue
    }
'@
            
            if ($content -match $afterAllPattern) {
                $content = $content -replace $afterAllPattern, $newAfterAll
            }

            # Step 5: Convert Should syntax to v5 (with dashes)
            Write-MigrationLog "  Converting Should syntax..." -Level Info
            
            # Order matters! Process compound operators first, then simpler ones
            
            # Should Not BeNullOrEmpty → Should -Not -BeNullOrEmpty
            $content = $content -replace 'Should Not BeNullOrEmpty\b', 'Should -Not -BeNullOrEmpty'
            
            # Should BeNullOrEmpty → Should -BeNullOrEmpty
            $content = $content -replace 'Should BeNullOrEmpty\b', 'Should -BeNullOrEmpty'
            
            # Should Throw → Should -Throw
            $content = $content -replace 'Should Throw\b', 'Should -Throw'
            
            # Should Not Be → Should -Not -Be (specific pattern)
            $content = $content -replace 'Should Not Be\b', 'Should -Not -Be'
            
            # Should Be → Should -Be (when not already dashed)
            $content = $content -replace '\| Should Be\b(?! -)', '| Should -Be'
            $content = $content -replace '(?<!\|)\s+Should Be\b(?! -)', ' Should -Be'
            
            # Should Not → Should -Not (catch any remaining)
            $content = $content -replace '\| Should Not\b(?! -)', '| Should -Not'
            $content = $content -replace '(?<!\|)\s+Should Not\b(?! -)', ' Should -Not'
            
            # Step 6: Write the modified content back
            if ($content -ne $originalContent) {
                if ($PSCmdlet.ShouldProcess($file, "Update to Pester v5 syntax")) {
                    Set-Content -Path $file -Value $content -NoNewline
                    Write-MigrationLog "  Successfully migrated: $file" -Level Success
                }
            }
            else {
                Write-MigrationLog "  No changes needed for: $file" -Level Info
            }

            # Step 7: Validate with Pester if requested
            if ($Validate) {
                Write-MigrationLog "  Validating with Pester..." -Level Info
                try {
                    $result = Invoke-Pester -Path $file -PassThru -Output None
                    if ($result.FailedCount -gt 0 -or $result.Result -eq 'Failed') {
                        Write-MigrationLog "  Validation FAILED: $($result.FailedCount) tests failed" -Level Error
                    }
                    else {
                        Write-MigrationLog "  Validation successful" -Level Success
                    }
                }
                catch {
                    Write-MigrationLog "  Validation error: $($_.Exception.Message)" -Level Error
                }
            }
        }
    }
}

end {
    Write-MigrationLog "Migration complete!" -Level Success
}
