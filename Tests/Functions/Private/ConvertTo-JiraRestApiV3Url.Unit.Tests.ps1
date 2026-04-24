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

            It "rewrites only the first /rest/api/2/ segment" {
                # Pathological input: /rest/api/2/ as a substring of a query
                # string. We accept this collateral damage because production
                # URLs do not contain /rest/api/2/ outside of the API root.
                $url = "https://acme.atlassian.net/rest/api/2/issue/12345"
                $result = ConvertTo-JiraRestApiV3Url -Url $url -IsCloud $true
                $result | Should -Be "https://acme.atlassian.net/rest/api/3/issue/12345"
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
