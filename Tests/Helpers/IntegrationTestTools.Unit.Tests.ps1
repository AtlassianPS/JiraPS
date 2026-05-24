#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeAll {
    . "$PSScriptRoot/IntegrationTestTools.ps1"
}

Describe 'Read-DotEnvFile' -Tag Unit {
    BeforeEach {
        [Environment]::SetEnvironmentVariable('JIRAPS_ENV_EXISTING', $null)
        [Environment]::SetEnvironmentVariable('JIRAPS_ENV_ALLOWED', $null)
        [Environment]::SetEnvironmentVariable('JIRAPS_ENV_EXCLUDED', $null)
    }

    AfterEach {
        [Environment]::SetEnvironmentVariable('JIRAPS_ENV_EXISTING', $null)
        [Environment]::SetEnvironmentVariable('JIRAPS_ENV_ALLOWED', $null)
        [Environment]::SetEnvironmentVariable('JIRAPS_ENV_EXCLUDED', $null)
    }

    It 'overwrites an existing process environment variable by default' {
        $envFile = Join-Path -Path $TestDrive -ChildPath 'existing.env'
        Set-Content -LiteralPath $envFile -Value 'JIRAPS_ENV_EXISTING=from-file'

        [Environment]::SetEnvironmentVariable('JIRAPS_ENV_EXISTING', 'from-process')

        Read-DotEnvFile -Path $envFile

        $env:JIRAPS_ENV_EXISTING | Should -Be 'from-file'
    }

    It 'loads missing variables that are not excluded' {
        $envFile = Join-Path -Path $TestDrive -ChildPath 'allowed.env'
        Set-Content -LiteralPath $envFile -Value 'JIRAPS_ENV_ALLOWED=from-file'

        Read-DotEnvFile -Path $envFile

        $env:JIRAPS_ENV_ALLOWED | Should -Be 'from-file'
    }

    It 'does not load excluded variables' {
        $envFile = Join-Path -Path $TestDrive -ChildPath 'excluded.env'
        Set-Content -LiteralPath $envFile -Value @(
            'JIRAPS_ENV_ALLOWED=from-file'
            'JIRAPS_ENV_EXCLUDED=from-file'
        )

        Read-DotEnvFile -Path $envFile -ExcludeName 'JIRAPS_ENV_EXCLUDED'

        $env:JIRAPS_ENV_ALLOWED | Should -Be 'from-file'
        $env:JIRAPS_ENV_EXCLUDED | Should -BeNullOrEmpty
    }
}

Describe 'Get-DotEnvExcludedName' -Tag Unit {
    BeforeEach {
        [Environment]::SetEnvironmentVariable('CI_JIRA_TYPE', $null)
    }

    AfterEach {
        [Environment]::SetEnvironmentVariable('CI_JIRA_TYPE', $null)
    }

    It 'does not exclude fixtures for Cloud runs' {
        Get-DotEnvExcludedName | Should -BeNullOrEmpty
    }

    It 'excludes Cloud fixture names for Server runs' {
        [Environment]::SetEnvironmentVariable('CI_JIRA_TYPE', 'Server')

        Get-DotEnvExcludedName | Should -Be @(
            'JIRA_TEST_PROJECT'
            'JIRA_TEST_ISSUE'
            'JIRA_TEST_GROUP'
            'JIRA_TEST_FILTER'
            'JIRA_TEST_VERSION'
        )
    }
}
