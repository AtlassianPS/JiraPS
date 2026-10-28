#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

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

Describe 'Remove-StaleTestResource' -Tag Unit {
    BeforeAll {
        $null = Initialize-TestEnvironment
    }

    BeforeEach {
        Mock Get-Date { [datetime]'2026-01-02T12:00:00' }
        Mock Get-JiraIssue { @() }
        Mock Get-JiraVersion {
            @(
                @{ Id = 1; Name = 'JiraPS-IntTest-Version-20260102100000-abcdef' }
                @{ Id = 2; Name = 'JiraPS-IntTest-Version-20260102113000-abcdef' }
                @{ Id = 3; Name = 'JiraPS-IntTest-Version-without-timestamp' }
                @{ Id = 4; Name = 'JiraPS-IntTest-Version-20261302100000-abcdef' }
                @{ Id = 5; Name = 'Other-Version-20260102100000-abcdef' }
            )
        }
        Mock Find-JiraFilter {
            @(
                @{ Id = 1; Name = 'JiraPS-IntTest-Filter-20260102100000-abcdef' }
                @{ Id = 2; Name = 'JiraPS-IntTest-Filter-20260102113000-abcdef' }
                @{ Id = 3; Name = 'JiraPS-IntTest-Filter-without-timestamp' }
                @{ Id = 4; Name = 'JiraPS-IntTest-Filter-20261302100000-abcdef' }
                @{ Id = 5; Name = 'Other-Filter-20260102100000-abcdef' }
            )
        }
        Mock Remove-JiraVersion {}
        Mock Remove-JiraFilter {}

        Remove-StaleTestResource -Fixtures @{ TestProject = 'TEST'; ReadOnly = $false } -MaxAge ([timespan]::FromHours(1)) -Force
    }

    It 'deletes only versions older than MaxAge and preserves active or unrecognized resources' {
        Should -Invoke Remove-JiraVersion -Times 1 -Exactly
        Should -Invoke Remove-JiraVersion -Times 1 -Exactly -ParameterFilter { $Version.Id -eq 1 }
    }

    It 'deletes only filters older than MaxAge and preserves active or unrecognized resources' {
        Should -Invoke Remove-JiraFilter -Times 1 -Exactly
        Should -Invoke Remove-JiraFilter -Times 1 -Exactly -ParameterFilter { $InputObject.Id -eq 1 }
    }
}

Describe 'Cloud integration token names' -Tag Unit {
    BeforeEach {
        $savedEnvironment = @{}
        foreach ($name in @(
                'CI_JIRA_TYPE',
                'JIRA_CLOUD_URL',
                'JIRA_CLOUD_USERNAME',
                'JIRA_CLOUD_PASSWORD',
                'JIRA_CLOUD_API_TOKEN',
                'JIRA_TEST_PROJECT',
                'JIRA_TEST_ISSUE'
            )) {
            $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
            [Environment]::SetEnvironmentVariable($name, $null)
        }
        $env:JIRA_CLOUD_URL = 'https://example.atlassian.net'
        $env:JIRA_CLOUD_USERNAME = 'test@example.test'
        $env:JIRA_TEST_PROJECT = 'TEST'
        $env:JIRA_TEST_ISSUE = 'TEST-1'
        $script:_EnvLoaded = $false
        $script:_CachedIntegrationEnv = $null
        Mock Resolve-ProjectRoot { $TestDrive }
    }

    AfterEach {
        foreach ($name in $savedEnvironment.Keys) {
            [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name])
        }
        $script:_EnvLoaded = $false
        $script:_CachedIntegrationEnv = $null
    }

    It 'uses the API token name ahead of a legacy process value' {
        $env:JIRA_CLOUD_PASSWORD = 'legacy-fixture'
        $env:JIRA_CLOUD_API_TOKEN = 'current-fixture'

        $configuration = Initialize-IntegrationEnvironment

        $configuration.Password | Should -Be 'current-fixture'
    }

    It 'continues to accept the legacy token name' {
        $env:JIRA_CLOUD_PASSWORD = 'legacy-fixture'

        $configuration = Initialize-IntegrationEnvironment

        $configuration.Password | Should -Be 'legacy-fixture'
    }
}
