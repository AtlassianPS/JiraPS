#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe 'GitHub Actions workflow triggers' -Tag Unit {
    It 'runs integration tests weekly and on demand' {
        $workflow = Get-Content "$PSScriptRoot/../../.github/workflows/integration_tests.yml" -Raw

        $workflow | Should -Match 'cron:\s*"0 5 \* \* 0"'
        $workflow | Should -Match 'workflow_dispatch:'
    }
}
