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
        $expectedStandardsSha = 'bd959dc3de7ee8426f89c31a62e0282e7140bd51'

        $workflowPaths = Get-ChildItem -Path (Join-Path -Path $projectRoot -ChildPath '.github/workflows') -File -Filter '*.yml' |
            Select-Object -ExpandProperty FullName

        $workflowActionMatches = foreach ($workflowPath in $workflowPaths) {
            $workflowContent = Get-Content -LiteralPath $workflowPath -Raw
            [regex]::Matches(
                $workflowContent,
                "AtlassianPS/AtlassianPS\.Standards/\.github/(?:actions|workflows)/[^@\s]+@(?<ref>[^\s]+)(?:\s+#\s*v(?<version>[0-9]+\.[0-9]+\.[0-9]+))?"
            ) | ForEach-Object {
                [PSCustomObject]@{
                    WorkflowPath = $workflowPath
                    Ref          = $_.Groups['ref'].Value
                    Version      = $_.Groups['version'].Value
                }
            }
        }

        @($workflowActionMatches).Count | Should -BeGreaterThan 0
        ($workflowActionMatches | Select-Object -ExpandProperty Version -Unique) | Should -Be @($standardsVersion)
        ($workflowActionMatches | Select-Object -ExpandProperty Ref -Unique) | Should -Be @($expectedStandardsSha)
    }

    It 'uses safe shared release workflows' {
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

        $workflowRoot = Join-Path -Path $projectRoot -ChildPath '.github/workflows'
        $releaseIntentContent = Get-Content -LiteralPath (Join-Path -Path $workflowRoot -ChildPath 'release_intent.yml') -Raw
        $continuousReleaseContent = Get-Content -LiteralPath (Join-Path -Path $workflowRoot -ChildPath 'continuous_release.yml') -Raw

        $releaseIntentContent | Should -Match 'pull_request_target:'
        $releaseIntentContent | Should -Match 'pull-requests:\s+read'
        $releaseIntentContent | Should -Match 'issues:\s+write'
        $releaseIntentContent | Should -Match 'validate-release-intent@[0-9a-f]{40}'
        $releaseIntentContent | Should -Not -Match 'actions/checkout|\brun:'
        $releaseIntentContent | Should -Not -Match '\bedited\b'

        $continuousReleaseContent | Should -Match 'workflows/module_release\.yml@[0-9a-f]{40}'
        $continuousReleaseContent | Should -Match '(?ms)workflow_run:.*?branches:\s*\[master\]'
        $continuousReleaseContent | Should -Match 'module-name:\s+JiraPS'
        $continuousReleaseContent | Should -Match "vars\.JIRAPS_CD_ENABLED == 'true'"
        $continuousReleaseContent | Should -Match '(?ms)options:\s+- major'
        $continuousReleaseContent | Should -Not -Match '(?m)^\s+tags:'

        Test-Path -LiteralPath (Join-Path -Path $workflowRoot -ChildPath 'release.yml') | Should -BeFalse
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

        $buildScriptContent | Should -Match 'Task SetSourceVersion'
        $buildScriptContent | Should -Match 'Task VerifyReleaseArtifact Package,'
        $buildScriptContent | Should -Not -Match '(?m)^Task Publish\b|PSGalleryAPIKey|Publish-Module'

        $changelogContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath 'CHANGELOG.md') -Raw
        $changelogContent | Should -Match '(?m)^## Unreleased\r?$'
        $changelogContent | Should -Not -Match '(?m)^## v3\.0\.0\b'
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
        $buildScriptContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath 'JiraPS.build.ps1') -Raw
        $testToolsContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath 'Tests/Helpers/TestTools.ps1') -Raw

        $setupScriptContent | Should -Match '\$buildRequirements\s*=\s*Import-PowerShellDataFile'
        $setupScriptContent | Should -Not -Match '\$standardsVersion\s*=\s*'''
        $setupScriptContent | Should -Match '-RequiredVersion\s+\$standardsVersion'

        $buildScriptContent | Should -Match '\$buildRequirements\s*=\s*Import-PowerShellDataFile'
        $buildScriptContent | Should -Match '-RequiredVersion\s+\$standardsRequirement\.RequiredVersion'
        $buildScriptContent | Should -Not -Match "AtlassianPS\.Standards.*RequiredVersion\s+'[0-9]+\.[0-9]+\.[0-9]+'"

        $testToolsContent | Should -Match '\$script:_BuildRequirements\s*=\s*Import-PowerShellDataFile'
        $testToolsContent | Should -Match '-RequiredVersion\s+\$script:_StandardsRequirement\.RequiredVersion'
        $testToolsContent | Should -Not -Match "AtlassianPS\.Standards.*RequiredVersion\s+'[0-9]+\.[0-9]+\.[0-9]+'"
    }
}
