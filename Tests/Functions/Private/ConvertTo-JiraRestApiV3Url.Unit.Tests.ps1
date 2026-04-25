#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraRestApiV3Url" -Tag 'Unit' {

        Context "Jira Server / Data Center" {
            It "returns the URL verbatim" {
                $url = "https://jira.example.com/rest/api/2/issue/12345"
                $result = ConvertTo-JiraRestApiV3Url -Url $url -IsCloud $false
                $result | Should -Be $url
            }

            It "preserves URLs that have no /rest/api/2/ segment" {
                $url = "https://jira.example.com/rest/agile/1.0/board"
                $result = ConvertTo-JiraRestApiV3Url -Url $url -IsCloud $false
                $result | Should -Be $url
            }
        }

        Context "Jira Cloud" {
            It "rewrites /rest/api/2/ to /rest/api/3/ in absolute URLs" {
                $url = "https://acme.atlassian.net/rest/api/2/issue/12345"
                $result = ConvertTo-JiraRestApiV3Url -Url $url -IsCloud $true
                $result | Should -Be "https://acme.atlassian.net/rest/api/3/issue/12345"
            }

            It "rewrites /rest/api/2/ to /rest/api/3/ in relative URLs" {
                $result = ConvertTo-JiraRestApiV3Url -Url "/rest/api/2/issue" -IsCloud $true
                $result | Should -Be "/rest/api/3/issue"
            }

            It "rewrites the path /rest/api/2/ but leaves /rest/api/2/ inside the query string alone" {
                # Pathological input: /rest/api/2/ appears both in the URL
                # path and as the value of a query parameter. We must
                # rewrite the path (so the API call lands on v3) but leave
                # the query string verbatim, so callback URLs etc. survive
                # the rewrite untouched.
                $url = "https://x/rest/api/2/issue?cb=/rest/api/2/foo"
                $result = ConvertTo-JiraRestApiV3Url -Url $url -IsCloud $true
                $result | Should -Be "https://x/rest/api/3/issue?cb=/rest/api/2/foo"
            }

            It "leaves /rest/api/2/ inside a fragment alone" {
                $url = "https://x/rest/api/2/issue#/rest/api/2/foo"
                $result = ConvertTo-JiraRestApiV3Url -Url $url -IsCloud $true
                $result | Should -Be "https://x/rest/api/3/issue#/rest/api/2/foo"
            }

            It "rewrites only the first /rest/api/2/ segment in the path" {
                # Defensive: a URL whose path embeds a second /rest/api/2/
                # segment should still only have the first one rewritten,
                # so nested-resource paths don't get double-mangled.
                $url = "https://x/rest/api/2/foo/rest/api/2/bar"
                $result = ConvertTo-JiraRestApiV3Url -Url $url -IsCloud $true
                $result | Should -Be "https://x/rest/api/3/foo/rest/api/2/bar"
            }

            It "leaves agile / service-desk URLs alone" {
                $url = "https://acme.atlassian.net/rest/agile/1.0/board/2"
                $result = ConvertTo-JiraRestApiV3Url -Url $url -IsCloud $true
                $result | Should -Be $url
            }

            It "returns an empty string verbatim" {
                $result = ConvertTo-JiraRestApiV3Url -Url '' -IsCloud $true
                $result | Should -Be ''
            }

            It "returns `$null verbatim" {
                $result = ConvertTo-JiraRestApiV3Url -Url $null -IsCloud $true
                $result | Should -BeNullOrEmpty
            }

            It "leaves URLs without /rest/api/2/ unchanged" {
                $url = "https://acme.atlassian.net/rest/api/3/issue/12345"
                $result = ConvertTo-JiraRestApiV3Url -Url $url -IsCloud $true
                $result | Should -Be $url
            }
        }
    }
}
