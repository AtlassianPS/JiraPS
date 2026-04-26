#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

<#
.SYNOPSIS
    Configuration validation tests that FAIL (not skip) when integration environment is not configured.

.DESCRIPTION
    These tests ensure that CI pipelines fail visibly when required secrets are missing,
    rather than silently skipping all integration tests and reporting success.

    Tagged as 'Smoke' so they run on every PR.
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Integration tests require plaintext credential conversion for API tokens')]
param()

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

Describe "Integration Test Configuration" -Tag 'Integration', 'Smoke', 'Cloud' {

    BeforeAll {
        . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"
    }

    Context "Required Environment Variables" {

        It "JIRA_CLOUD_URL is configured" {
            $value = [Environment]::GetEnvironmentVariable('JIRA_CLOUD_URL')
            $value | Should -Not -BeNullOrEmpty -Because "JIRA_CLOUD_URL secret must be configured in repository settings"
        }

        It "JIRA_CLOUD_USERNAME is configured" {
            $value = [Environment]::GetEnvironmentVariable('JIRA_CLOUD_USERNAME')
            $value | Should -Not -BeNullOrEmpty -Because "JIRA_CLOUD_USERNAME secret must be configured in repository settings"
        }

        It "JIRA_CLOUD_PASSWORD is configured" {
            $value = [Environment]::GetEnvironmentVariable('JIRA_CLOUD_PASSWORD')
            $value | Should -Not -BeNullOrEmpty -Because "JIRA_CLOUD_PASSWORD secret must be configured in repository settings"
        }

        It "JIRA_TEST_PROJECT is configured" {
            $value = [Environment]::GetEnvironmentVariable('JIRA_TEST_PROJECT')
            $value | Should -Not -BeNullOrEmpty -Because "JIRA_TEST_PROJECT secret must be configured in repository settings"
        }

        It "JIRA_TEST_ISSUE is configured" {
            $value = [Environment]::GetEnvironmentVariable('JIRA_TEST_ISSUE')
            $value | Should -Not -BeNullOrEmpty -Because "JIRA_TEST_ISSUE secret must be configured in repository settings"
        }
    }

    Context "Server Connectivity" {

        It "can connect to Jira Cloud server" {
            $env = Initialize-IntegrationEnvironment
            if (-not $env) {
                Set-ItResult -Skipped -Because "Environment not configured"
                return
            }

            Set-JiraConfigServer -Server $env.CloudUrl

            $serverInfo = Get-JiraServerInformation -ErrorAction Stop
            $serverInfo | Should -Not -BeNullOrEmpty -Because "Should be able to reach Jira server"
        }

        It "can authenticate with API token (recommended Cloud auth)" {
            $env = Initialize-IntegrationEnvironment
            if (-not $env) {
                Set-ItResult -Skipped -Because "Environment not configured"
                return
            }

            # Use -ApiToken/-EmailAddress which is the documented happy path for Jira Cloud
            $secureToken = ConvertTo-SecureString -String $env.Password -AsPlainText -Force

            $session = New-JiraSession -ApiToken $secureToken -EmailAddress $env.Username -ErrorAction Stop
            $session | Should -Not -BeNullOrEmpty -Because "Should be able to authenticate with API token"

            Remove-JiraSession -ErrorAction SilentlyContinue
        }
    }
}
