#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }
BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
    $script:Skip = Skip-IntegrationTest
}
Describe 'Cloud gateway token coverage' -Tag Integration, Cloud -Skip:$Skip {
    BeforeAll {
        . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"
        $script:integration = Initialize-IntegrationEnvironment
    }
    It 'validates gateway metadata, identity and issue read for <Kind> tokens' -ForEach @(
        @{ Kind = 'scoped'; Variable = 'JIRA_CLOUD_SCOPED_API_TOKEN'; LegacyVariable = 'JIRA_CLOUD_SCOPED_TOKEN' }
        @{ Kind = 'unscoped'; Variable = 'JIRA_CLOUD_API_TOKEN'; LegacyVariable = 'JIRA_CLOUD_UNSCOPED_TOKEN' }
    ) {
        $token = [Environment]::GetEnvironmentVariable($Variable)
        if (-not $token) { $token = [Environment]::GetEnvironmentVariable($LegacyVariable) }
        if (-not $token) {
            Set-ItResult -Skipped -Because "$Variable is unavailable; this token-kind acceptance criterion is unverified."
            return
        }
        $connection = $null
        try {
            $connection = Connect-Jira -Name ("gateway-" + $Kind) -Uri $integration.CloudUrl -EmailAddress $integration.Username -ApiToken $token
            $connection.DeploymentType | Should -Be Cloud
            $connection.Username | Should -Not -BeNullOrEmpty
            $connection.CloudId | Should -Match '^[0-9a-f-]{36}$'
            $connection.BaseUri.Host | Should -Be api.atlassian.com
            $connection.BaseUri.AbsolutePath | Should -Be ("/ex/jira/" + $connection.CloudId)
            Get-JiraIssue -Key $integration.TestIssue -Fields summary -Connection $connection | Should -Not -BeNullOrEmpty
        }
        finally {
            $token = $null
            if ($connection) { $connection | Disconnect-Jira }
        }
    }
}
