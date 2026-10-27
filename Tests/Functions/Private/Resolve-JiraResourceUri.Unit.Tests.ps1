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

    Describe 'Resolve-JiraResourceUri' -Tag Unit {
        BeforeAll {
            $script:gateway = AtlassianPS.Configuration\New-AtlassianConnectionContext -Name uri-gateway -Product Jira -BaseUri https://api.atlassian.com/ex/jira/11111111-1111-1111-1111-111111111111 -SiteUri https://site.atlassian.net -CloudId 11111111-1111-1111-1111-111111111111 -Anonymous
            $script:server = AtlassianPS.Configuration\New-AtlassianConnectionContext -Name uri-server -Product Jira -BaseUri https://jira.example.com/jira -Anonymous
        }
        AfterAll {
            $gateway.Dispose()
            $server.Dispose()
        }

        It 'preserves relative queries and the Cloud gateway prefix' {
            $result = Resolve-JiraResourceUri -Uri '/rest/api/2/search?jql=project%3DTEST&startAt=5' -RequestContext $gateway

            $result.AbsoluteUri | Should -Be 'https://api.atlassian.com/ex/jira/11111111-1111-1111-1111-111111111111/rest/api/2/search?jql=project%3DTEST&startAt=5'
        }

        It 'maps matching Cloud REST links and preserves their query' {
            (Resolve-JiraResourceUri -Uri 'https://site.atlassian.net/rest/api/3/issue/1?fields=summary' -RequestContext $gateway).AbsoluteUri |
                Should -Be 'https://api.atlassian.com/ex/jira/11111111-1111-1111-1111-111111111111/rest/api/3/issue/1?fields=summary'
        }

        It 'preserves a Data Center application context path' {
            (Resolve-JiraResourceUri -Uri '/rest/api/2/issue/TEST-1' -RequestContext $server).AbsoluteUri | Should -Be 'https://jira.example.com/jira/rest/api/2/issue/TEST-1'
        }

        It 'rejects foreign origins, other gateways and path escapes' -ForEach @(
            @{ Resource = 'https://foreign.example.com/rest/api/2/issue/1' }
            @{
                Resource = 'https://api.atlassian.com/ex/jira/22222222-2222-2222-2222-222222222222/rest/api/2/issue/1'
            }
            @{ Resource = '//foreign.example.com/rest/api/2/issue/1' }
            @{ Resource = '/rest/../private' }
            @{ Resource = '/rest/%2e%2e/private' }
            @{ Resource = '/rest/%252e%252e/private' }
            @{ Resource = '/rest/api/2/issue/1#fragment' }
        ) {
            { Resolve-JiraResourceUri -Uri $Resource -RequestContext $gateway } | Should -Throw
        }

        It 'rejects absolute URLs outside the Data Center application path' {
            { Resolve-JiraResourceUri -Uri 'https://jira.example.com/other/rest/api/2/issue/1' -RequestContext $server } | Should -Throw
        }
    }
}
