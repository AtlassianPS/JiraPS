#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }
BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}
Describe 'Product module lifecycle' -Tag Unit {
    BeforeAll {
        . "$PSScriptRoot/../../Helpers/TestTools.ps1"
        $script:moduleToTest = Initialize-TestEnvironment
    }
    It 'preserves shared connections when Jira unloads and imports again' {
        $jira = New-AtlassianConnectionContext -Name lifecycle-jira -Product Jira -BaseUri https://jira.example.com -Anonymous
        $other = New-AtlassianConnectionContext -Name lifecycle-other -Product TestProduct -BaseUri https://other.example.com -Anonymous
        foreach ($candidate in @($jira, $other)) {
            $candidate.SetValidationResult('Server', $null)
            $null = Register-AtlassianConnection -Connection $candidate
        }
        try {
            Remove-Module JiraPS -Force
            $jira.State | Should -Be Active
            $other.State | Should -Be Active
            Import-Module $moduleToTest -Global
            (Get-JiraConnection -Name lifecycle-jira).InstanceId | Should -Be $jira.InstanceId
            (Get-AtlassianConnection -Product TestProduct -Default).InstanceId | Should -Be $other.InstanceId
        }
        finally {
            foreach ($candidate in @($jira, $other)) {
                if ($candidate.State -eq 'Active') { Disconnect-AtlassianConnection -Connection $candidate }
            }
        }
    }
}
