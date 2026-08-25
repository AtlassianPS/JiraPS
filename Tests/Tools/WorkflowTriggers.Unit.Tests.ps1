#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe 'GitHub Actions workflow triggers' -Tag Unit {
    BeforeAll {
        . "$PSScriptRoot/../Helpers/TestTools.ps1"
        $script:workflowRoot = Join-Path (Resolve-ProjectRoot) '.github/workflows'
    }

    It 'runs integration tests weekly and on demand' {
        $workflow = Get-Content (Join-Path $script:workflowRoot 'integration_tests.yml') -Raw

        $workflow | Should -Match 'cron:\s*"0 5 \* \* 0"'
        $workflow | Should -Match 'workflow_dispatch:'
    }
}
