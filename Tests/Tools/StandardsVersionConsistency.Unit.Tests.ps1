#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe 'AtlassianPS.Standards version consistency' -Tag Unit {
    It 'keeps workflow Standards action pins aligned with build.requirements' {
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

        $workflowPaths = Get-ChildItem -Path (Join-Path -Path $projectRoot -ChildPath '.github/workflows') -File -Filter '*.yml' |
            Select-Object -ExpandProperty FullName

        $workflowActionMatches = foreach ($workflowPath in $workflowPaths) {
            $workflowContent = Get-Content -LiteralPath $workflowPath -Raw
            [regex]::Matches(
                $workflowContent,
                "AtlassianPS/AtlassianPS\.Standards/\.github/actions/[^@\s]+@(?<sha>[0-9a-f]{40})\s+#\s*v(?<version>[0-9]+\.[0-9]+\.[0-9]+)"
            ) | ForEach-Object {
                [PSCustomObject]@{
                    WorkflowPath = $workflowPath
                    Sha          = $_.Groups['sha'].Value
                    Version      = $_.Groups['version'].Value
                }
            }
        }

        @($workflowActionMatches).Count | Should -BeGreaterThan 0
        ($workflowActionMatches | Select-Object -ExpandProperty Version -Unique) | Should -Be @($standardsVersion)
        @($workflowActionMatches | Select-Object -ExpandProperty Sha -Unique).Count | Should -Be 1
    }

    It 'uses the shared Standards release tag resolver action' {
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

        $releaseWorkflowContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath '.github/workflows/release.yml') -Raw

        $releaseWorkflowContent | Should -Match 'AtlassianPS/AtlassianPS\.Standards/\.github/actions/resolve-release-tag@[0-9a-f]{40}'
        $releaseWorkflowContent | Should -Not -Match 'Tools/Resolve-ReleaseTag\.ps1'
    }

    It 'keeps published manifest release notes sourced from the changelog' {
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

        $buildScriptContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath 'JiraPS.build.ps1') -Raw

        $buildScriptContent | Should -Not -Match 'function\s+Get-JiraPSReleaseNotesFromChangelog'
        $buildScriptContent | Should -Match 'Get-AtlassianPSReleaseNotesFromChangelog[\s\S]+CHANGELOG\.md'
        $buildScriptContent | Should -Match 'Set-AtlassianPSModuleManifestVersion[\s\S]+-ReleaseNotes\s+\$releaseNotes'
        $buildScriptContent | Should -Not -Match 'ConvertTo-JiraPSModuleVersion'

        $releaseWorkflowContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath '.github/workflows/release.yml') -Raw
        $releaseWorkflowContent | Should -Match 'AtlassianPS/AtlassianPS\.Standards/\.github/actions/build-release-notes@[0-9a-f]{40}'
        $releaseWorkflowContent | Should -Match 'body_path:\s+\$\{\{\s*steps\.release_notes\.outputs\.release_notes_path\s*\}\}'
        $releaseWorkflowContent | Should -Match 'build-release-notes[\s\S]+Publish module'
        $releaseWorkflowContent | Should -Not -Match 'changelog-to-release|changelog\.configuration\.json|steps\.changelog\.outputs\.body|Get-AtlassianPSReleaseNotesFromChangelog[\s\S]+Set-Content'
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
