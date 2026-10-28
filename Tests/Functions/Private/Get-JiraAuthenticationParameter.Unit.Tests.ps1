#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'Get-JiraAuthenticationParameter' -Tag Unit {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
        }

        It 'returns an empty hashtable when authentication is omitted' {
            $result = Get-JiraAuthenticationParameter -BoundParameters @{}

            $result | Should -BeOfType [Hashtable]
            $result.Count | Should -Be 0
        }

        It 'excludes connection selectors and operation fields without changing the input' {
            $boundParameters = @{
                Name                = 'work'
                Uri                 = 'https://jira.example.com'
                Connection          = 'connection-selector'
                Key                 = 'TEST-1'
                ErrorAction         = 'Stop'
                PersonalAccessToken = 'test-token'
            }

            $result = Get-JiraAuthenticationParameter -BoundParameters $boundParameters

            $result.Count | Should -Be 1
            $result.PersonalAccessToken | Should -Be 'test-token'
            $result.PersonalAccessToken = 'replacement-token'
            $boundParameters.Count | Should -Be 6
            $boundParameters.PersonalAccessToken | Should -Be 'test-token'
        }

        It 'preserves explicitly supplied <Description> for downstream validation' -ForEach @(
            @{ ParameterName = 'Credential'; Value = [PSCredential]::Empty; Description = 'empty credentials' }
            @{ ParameterName = 'Credential'; Value = $null; Description = 'null credentials' }
            @{ ParameterName = 'EmailAddress'; Value = ''; Description = 'an empty email address' }
            @{ ParameterName = 'ApiToken'; Value = $null; Description = 'a null API token' }
            @{ ParameterName = 'ApiToken'; Value = [System.Security.SecureString]::new(); Description = 'a SecureString API token' }
            @{ ParameterName = 'PersonalAccessToken'; Value = ''; Description = 'an empty personal access token' }
            @{ ParameterName = 'Anonymous'; Value = [System.Management.Automation.SwitchParameter]::new($false); Description = 'a false anonymous switch' }
        ) {
            $boundParameters = @{ $ParameterName = $Value }

            $result = Get-JiraAuthenticationParameter -BoundParameters $boundParameters

            $result.Count | Should -Be 1
            $result.ContainsKey($ParameterName) | Should -BeTrue
            [Object]::ReferenceEquals($result[$ParameterName], $boundParameters[$ParameterName]) | Should -BeTrue
        }

        It 'excludes the user email field while preserving authentication overrides' {
            $boundParameters = @{
                EmailAddress = 'new-user@example.com'
                Credential   = [PSCredential]::Empty
            }

            $result = Get-JiraAuthenticationParameter -BoundParameters $boundParameters -UserEmailField

            $result.Count | Should -Be 1
            $result.ContainsKey('EmailAddress') | Should -BeFalse
            $result.Credential | Should -Be ([PSCredential]::Empty)
            $boundParameters.EmailAddress | Should -Be 'new-user@example.com'
        }

        It 'forwards the authentication email address when it is not a user field' {
            $boundParameters = @{
                EmailAddress = 'identity@example.com'
                ApiToken     = 'test-token'
            }

            $result = Get-JiraAuthenticationParameter -BoundParameters $boundParameters

            $result.Count | Should -Be 2
            $result.EmailAddress | Should -Be 'identity@example.com'
            $result.ApiToken | Should -Be 'test-token'
        }
    }
}
