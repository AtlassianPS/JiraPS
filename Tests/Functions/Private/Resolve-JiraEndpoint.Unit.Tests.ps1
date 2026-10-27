#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

BeforeAll {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {

    Describe 'Resolve-JiraEndpoint' -Tag Unit {
        It 'discovers the normal Cloud site without passing authentication' {
            Mock Invoke-JiraMethod { [PSCustomObject]@{ cloudId = '11111111-1111-1111-1111-111111111111' } }
            $result = Resolve-JiraEndpoint -Uri https://site.atlassian.net -ApiToken

            $result.BaseUri.AbsoluteUri | Should -Be 'https://api.atlassian.com/ex/jira/11111111-1111-1111-1111-111111111111'
            $result.SiteUri.AbsoluteUri | Should -Be 'https://site.atlassian.net/'
            Should -Invoke Invoke-JiraMethod -Exactly 1 -ParameterFilter {
                $Discovery -and "$Uri" -eq 'https://site.atlassian.net/_edge/tenant_info' -and
                -not $PSBoundParameters.ContainsKey('Headers') -and -not $PSBoundParameters.ContainsKey('Credential') -and
                -not $PSBoundParameters.ContainsKey('ApiToken') -and -not $PSBoundParameters.ContainsKey('RequestContext')
            }
        }

        It 'rejects missing or malformed discovery identities' -ForEach @(
            @{ CloudId = $null }
            @{ CloudId = 'not-a-guid' }
            @{ CloudId = '00000000-0000-0000-0000-000000000000' }
            @{ CloudId = 'https://foreign.example.com' }
        ) {
            Mock Invoke-JiraMethod { [PSCustomObject]@{ cloudId = $CloudId } }

            { Resolve-JiraEndpoint -Uri https://site.atlassian.net -ApiToken } | Should -Throw -ExpectedMessage '*discovery failed*'
        }

        It 'fails closed when discovery fails' {
            Mock Invoke-JiraMethod { throw 'Non-JSON or redirected response.' }

            { Resolve-JiraEndpoint -Uri https://site.atlassian.net -ApiToken } | Should -Throw -ExpectedMessage '*discovery failed*'
        }

        It 'accepts an explicit gateway without discovery' {
            Mock Invoke-JiraMethod { throw 'Discovery must not run.' }
            $result = Resolve-JiraEndpoint -Uri https://api.atlassian.com/ex/jira/11111111-1111-1111-1111-111111111111 -ApiToken

            $result.CloudId | Should -Be '11111111-1111-1111-1111-111111111111'
            Should -Invoke Invoke-JiraMethod -Times 0
        }

        It 'requires HTTPS for Cloud and permits explicit local Data Center HTTP' {
            { Resolve-JiraEndpoint -Uri http://site.atlassian.net -ApiToken } | Should -Throw
            (Resolve-JiraEndpoint -Uri http://localhost:2990/jira).BaseUri.AbsoluteUri | Should -Be 'http://localhost:2990/jira'
        }
    }
}
