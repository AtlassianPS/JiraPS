#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Resolve-JiraRequestContext" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            function script:Invoke-ResolveJiraRequestContext {
                [CmdletBinding(SupportsPaging)]
                param(
                    [Parameter(Mandatory)]
                    [Uri]
                    $Uri,

                    [Hashtable]
                    $GetParameter = @{},

                    [ValidateRange(1, [int]::MaxValue)]
                    [int]
                    $DefaultPageSize = 25
                )

                Resolve-JiraRequestContext -Uri $Uri -GetParameter $GetParameter -DefaultPageSize $DefaultPageSize -Cmdlet $PSCmdlet
            }
        }

        It "resolves a relative URI against the configured Jira server and applies default page size" {
            Mock Get-JiraConfigServer -ModuleName 'JiraPS' { 'https://jira.example.com' }

            $result = Invoke-ResolveJiraRequestContext -Uri '/rest/api/2/search'

            $result.Uri.AbsoluteUri | Should -Be 'https://jira.example.com/rest/api/2/search'
            $result.PaginatedUri.AbsoluteUri | Should -Match '\?maxResults=25$'
        }

        It "merges URI query and -GetParameter with caller values taking precedence" {
            $result = Invoke-ResolveJiraRequestContext -Uri 'https://jira.example.com/rest/api/2/search?jql=fromUri' -GetParameter @{ jql = 'fromArg'; expand = 'names' }

            $result.Uri.Query | Should -BeNullOrEmpty
            $result.PaginatedUri.AbsoluteUri | Should -Match 'jql=fromArg'
            $result.PaginatedUri.AbsoluteUri | Should -Match 'expand=names'
            $result.PaginatedUri.AbsoluteUri | Should -Match 'maxResults=25'
        }

        It "applies paging overrides from the caller cmdlet" {
            $result = Invoke-ResolveJiraRequestContext -Uri 'https://jira.example.com/rest/api/2/search' -First 5 -Skip 2

            $result.PaginatedUri.AbsoluteUri | Should -Match 'maxResults=5'
            $result.PaginatedUri.AbsoluteUri | Should -Match 'startAt=2'
        }

        It "preserves existing maxResults when -First is larger" {
            $result = Invoke-ResolveJiraRequestContext -Uri 'https://jira.example.com/rest/api/2/search?maxResults=10' -First 25

            $result.PaginatedUri.AbsoluteUri | Should -Match 'maxResults=10'
        }

        It "throws for relative URIs that do not start with '/'" {
            { Invoke-ResolveJiraRequestContext -Uri 'hello' } | Should -Throw -ExpectedMessage "*must start with '/'*"
        }

        It "throws when a relative URI is used without a configured Jira server" {
            Mock Get-JiraConfigServer -ModuleName 'JiraPS' { $null }

            { Invoke-ResolveJiraRequestContext -Uri '/rest/api/2/search' } | Should -Throw -ExpectedMessage "*no Jira server is configured*"
        }

        It "throws when resolving a relative URI still results in a non-absolute URI" {
            Mock Get-JiraConfigServer -ModuleName 'JiraPS' { 'jira.example.com' }

            { Invoke-ResolveJiraRequestContext -Uri '/rest/api/2/search' } | Should -Throw -ExpectedMessage "*must be an absolute URI*"
        }
    }
}
