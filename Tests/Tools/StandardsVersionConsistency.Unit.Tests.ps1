#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe 'AtlassianPS.Standards version consistency' -Tag Unit {
    It 'keeps build and workflow pins aligned with build.requirements' {
        $projectRoot = if (
            $env:BHProjectPath -and
            (Test-Path -LiteralPath (Join-Path -Path $env:BHProjectPath -ChildPath 'CODEOWNERS'))
        ) {
            (Resolve-Path -LiteralPath $env:BHProjectPath).ProviderPath
        }
        else {
            $candidate = (Resolve-Path -LiteralPath $PSScriptRoot).ProviderPath
            while ($candidate -and ($candidate -ne [System.IO.Path]::GetPathRoot($candidate))) {
                if (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'CODEOWNERS')) {
                    break
                }

                $candidate = Split-Path -Path $candidate -Parent
            }

            if (-not $candidate -or -not (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'CODEOWNERS'))) {
                throw "Could not resolve repository root from '$PSScriptRoot'."
            }

            $candidate
        }

        $buildRequirementsPath = Join-Path -Path $projectRoot -ChildPath 'Tools/build.requirements.psd1'
        $buildRequirements = Import-PowerShellDataFile -Path $buildRequirementsPath
        $standardsRequirement = $buildRequirements |
            Where-Object { $_.ModuleName -eq 'AtlassianPS.Standards' } |
            Select-Object -First 1
        $standardsVersion = [string] $standardsRequirement.RequiredVersion
        $standardsVersionShaMap = @{
            '0.1.6' = '9a9367e22847bd24f86208ed2d98d207b0e2a3b3'
        }

        if (-not $standardsVersionShaMap.ContainsKey($standardsVersion)) {
            throw "No pinned workflow SHA mapping defined for AtlassianPS.Standards version '$standardsVersion'."
        }

        $expectedWorkflowActionSha = $standardsVersionShaMap[$standardsVersion]

        $buildScriptPath = Join-Path -Path $projectRoot -ChildPath 'JiraPS.build.ps1'
        $buildScriptContent = Get-Content -LiteralPath $buildScriptPath -Raw
        $buildScriptPin = [regex]::Match(
            $buildScriptContent,
            "(?s)#requires\s+-Modules\s+@\{\s*ModuleName\s*=\s*'AtlassianPS\.Standards';\s*ModuleVersion\s*=\s*'([^']+)';\s*MaximumVersion\s*=\s*'([^']+)'"
        )

        $buildScriptPin.Success | Should -BeTrue
        $buildScriptPin.Groups[1].Value | Should -Be $standardsVersion
        $buildScriptPin.Groups[2].Value | Should -Be $standardsVersion

        $workflowPaths = @(
            (Join-Path -Path $projectRoot -ChildPath '.github/workflows/ci.yml'),
            (Join-Path -Path $projectRoot -ChildPath '.github/workflows/integration_tests.yml'),
            (Join-Path -Path $projectRoot -ChildPath '.github/workflows/release.yml'),
            (Join-Path -Path $projectRoot -ChildPath '.github/workflows/copilot-setup-steps.yml')
        )

        foreach ($workflowPath in $workflowPaths) {
            $workflowContent = Get-Content -LiteralPath $workflowPath -Raw
            $versionMatches = [regex]::Matches(
                $workflowContent,
                "setup-powershell@(?<sha>[0-9a-f]{40})\s+#\s*v(?<version>[0-9]+\.[0-9]+\.[0-9]+)"
            )

            $versionMatches.Count | Should -BeGreaterThan 0
            foreach ($versionMatch in $versionMatches) {
                $versionMatch.Groups['version'].Value | Should -Be $standardsVersion
                $versionMatch.Groups['sha'].Value | Should -Be $expectedWorkflowActionSha
            }
        }
    }

    It 'reads AtlassianPS.Standards version from build.requirements in tool scripts' {
        $projectRoot = if (
            $env:BHProjectPath -and
            (Test-Path -LiteralPath (Join-Path -Path $env:BHProjectPath -ChildPath 'CODEOWNERS'))
        ) {
            (Resolve-Path -LiteralPath $env:BHProjectPath).ProviderPath
        }
        else {
            $candidate = (Resolve-Path -LiteralPath $PSScriptRoot).ProviderPath
            while ($candidate -and ($candidate -ne [System.IO.Path]::GetPathRoot($candidate))) {
                if (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'CODEOWNERS')) {
                    break
                }

                $candidate = Split-Path -Path $candidate -Parent
            }

            if (-not $candidate -or -not (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'CODEOWNERS'))) {
                throw "Could not resolve repository root from '$PSScriptRoot'."
            }

            $candidate
        }

        $setupScriptContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath 'Tools/setup.ps1') -Raw
        $updateScriptContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath 'Tools/update.dependencies.ps1') -Raw

        $setupScriptContent | Should -Match '\$buildRequirements\s*=\s*Import-PowerShellDataFile'
        $setupScriptContent | Should -Not -Match '\$standardsVersion\s*=\s*'''
        $setupScriptContent | Should -Match '-RequiredVersion\s+\$standardsVersion'

        $updateScriptContent | Should -Match '\$buildRequirements\s*=\s*Import-PowerShellDataFile'
        $updateScriptContent | Should -Not -Match '\$standardsVersion\s*=\s*'''
        $updateScriptContent | Should -Match '-RequiredVersion\s+\$standardsVersion'
    }
}
