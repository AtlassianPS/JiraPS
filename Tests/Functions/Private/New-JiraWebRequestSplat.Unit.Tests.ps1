#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "New-JiraWebRequestSplat" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
        }

        It "defaults ContentType only when a body is supplied" {
            Mock Get-JiraSession -ModuleName 'JiraPS' { $null }

            $withBody = New-JiraWebRequestSplat -Uri 'https://jira.example.com/rest/api/2/issue' -Method Post -Headers @{} -Body '{}' -DefaultContentType 'application/json; charset=utf-8'
            $withoutBody = New-JiraWebRequestSplat -Uri 'https://jira.example.com/rest/api/2/issue' -Method Post -Headers @{} -InFile './attachment.bin' -DefaultContentType 'application/json; charset=utf-8'

            $withBody.ContentType | Should -Be 'application/json; charset=utf-8'
            $withoutBody.ContainsKey('ContentType') | Should -BeFalse
        }

        It "honors explicit Content-Type header and removes it from Headers" {
            Mock Get-JiraSession -ModuleName 'JiraPS' { $null }

            $headers = @{
                'Content-Type' = 'text/plain'
                'X-Trace'      = 'abc123'
            }
            $result = New-JiraWebRequestSplat -Uri 'https://jira.example.com/rest/api/2/issue' -Method Post -Headers $headers -Body '{}'

            $result.ContentType | Should -Be 'text/plain'
            $result.Headers['X-Trace'] | Should -Be 'abc123'
            $result.Headers.ContainsKey('Content-Type') | Should -BeFalse
        }

        It "uses SessionVariable and drops WebSession when -StoreSession is set" {
            Mock Get-JiraSession -ModuleName 'JiraPS' {
                [PSCustomObject]@{
                    WebSession = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
                }
            }

            $result = New-JiraWebRequestSplat -Uri 'https://jira.example.com/rest/api/2/myself' -Method Get -Headers @{} -StoreSession

            $result.SessionVariable | Should -Be 'newSessionVar'
            $result.ContainsKey('WebSession') | Should -BeFalse
        }
    }
}
