#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe 'AtlassianPS.Standards version consistency' -Tag Unit {
    It 'keeps the shared Standards action pin aligned with build.requirements' {
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

        $setupActionPath = Join-Path -Path $projectRoot -ChildPath '.github/actions/setup-standards/action.yml'
        $setupActionContent = Get-Content -LiteralPath $setupActionPath -Raw
        $setupActionPin = [regex]::Match(
            $setupActionContent,
            "AtlassianPS/AtlassianPS\.Standards/\.github/actions/setup-powershell@(?<sha>[0-9a-f]{40})\s+#\s*v(?<version>[0-9]+\.[0-9]+\.[0-9]+)"
        )

        $setupActionPin.Success | Should -BeTrue
        $setupActionPin.Groups['version'].Value | Should -Be $standardsVersion

        $workflowPaths = Get-ChildItem -Path (Join-Path -Path $projectRoot -ChildPath '.github/workflows') -File -Filter '*.yml' |
            Select-Object -ExpandProperty FullName

        $workflowActionMatches = foreach ($workflowPath in $workflowPaths) {
            $workflowContent = Get-Content -LiteralPath $workflowPath -Raw
            $workflowContent | Should -Not -Match 'AtlassianPS/AtlassianPS\.Standards/\.github/actions/setup-powershell'
            [regex]::Matches($workflowContent, 'uses:\s+\./\.github/actions/setup-standards') | ForEach-Object {
                [PSCustomObject]@{
                    WorkflowPath = $workflowPath
                }
            }
        }

        @($workflowActionMatches).Count | Should -BeGreaterThan 0
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
        $buildScriptContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath 'JiraPS.build.ps1') -Raw
        $testToolsContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath 'Tests/Helpers/TestTools.ps1') -Raw

        $setupScriptContent | Should -Match '\$buildRequirements\s*=\s*Import-PowerShellDataFile'
        $setupScriptContent | Should -Not -Match '\$standardsVersion\s*=\s*'''
        $setupScriptContent | Should -Match '-RequiredVersion\s+\$standardsVersion'

        $updateScriptContent | Should -Match '\$buildRequirements\s*=\s*Import-PowerShellDataFile'
        $updateScriptContent | Should -Not -Match '\$standardsVersion\s*=\s*'''
        $updateScriptContent | Should -Match '-RequiredVersion\s+\$standardsVersion'
        $updateScriptContent | Should -Match '\$PSCmdlet\.ShouldProcess\('

        $buildScriptContent | Should -Match '\$buildRequirements\s*=\s*Import-PowerShellDataFile'
        $buildScriptContent | Should -Match '-RequiredVersion\s+\$standardsRequirement\.RequiredVersion'
        $buildScriptContent | Should -Not -Match "AtlassianPS\.Standards.*RequiredVersion\s+'[0-9]+\.[0-9]+\.[0-9]+'"

        $testToolsContent | Should -Match '\$script:_BuildRequirements\s*=\s*Import-PowerShellDataFile'
        $testToolsContent | Should -Match '-RequiredVersion\s+\$script:_StandardsRequirement\.RequiredVersion'
        $testToolsContent | Should -Not -Match "AtlassianPS\.Standards.*RequiredVersion\s+'[0-9]+\.[0-9]+\.[0-9]+'"
    }
}
