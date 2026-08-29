#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe 'GitHub Actions workflow triggers' -Tag Unit {
    BeforeAll {
        . "$PSScriptRoot/../Helpers/TestTools.ps1"
        $script:projectRoot = Resolve-ProjectRoot
        $script:workflowRoot = Join-Path $script:projectRoot '.github/workflows'
        $script:integrationWorkflow = Get-Content (Join-Path $script:workflowRoot 'integration_tests.yml') -Raw
    }

    It 'runs integration tests weekly and on demand' {
        $script:integrationWorkflow | Should -Match 'cron:\s*"0 5 \* \* 0"'
        $script:integrationWorkflow | Should -Match 'workflow_dispatch:'
    }

    It 'retains integration diagnostics briefly and uploads container logs on demand' {
        ([regex]::Matches($script:integrationWorkflow, 'retention-days:\s+14')).Count | Should -Be 2
        ([regex]::Matches($script:integrationWorkflow, 'retention-days:\s+7')).Count | Should -Be 1
        ([regex]::Matches($script:integrationWorkflow, "failure\(\) \|\| inputs\.debug \|\| runner\.debug == '1'")).Count | Should -Be 2
    }

    It 'checks routine container dependencies monthly' {
        $dependabot = Get-Content (Join-Path $script:projectRoot '.github/dependabot.yml') -Raw

        ([regex]::Matches($dependabot, 'package-ecosystem:\s*"(?:devcontainers|docker|docker-compose)"[\s\S]*?interval:\s*"?monthly"?')).Count | Should -Be 3
        $dependabot | Should -Match 'package-ecosystem:\s*"github-actions"[\s\S]*?interval:\s*"?weekly"?'
        $dependabot | Should -Match 'ignore:[\s\S]+dependency-name:\s*"AtlassianPS/AtlassianPS\.Standards\*"'
    }
}
