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

    Describe 'Resolve-JiraIssueObject' -Tag Unit {
        BeforeEach {
            $script:source = New-AtlassianConnectionContext -Name nested-issue -Product Jira -BaseUri https://jira.example.com -PersonalAccessToken source-secret
            $source.SetValidationResult('Server', 'source-user')
            $null = Register-AtlassianConnection -Connection $source
            $script:context = Resolve-AtlassianRequestContext -Product Jira -Connection $source -PersonalAccessToken override-secret
        }

        AfterEach {
            $context.Dispose()
            Disconnect-AtlassianConnection -Connection $source
        }

        It 'resolves a stub with the effective override identity and isolated cookies' {
            Mock Get-JiraIssue { [AtlassianPS.JiraPS.Issue]@{ Key = $Issue.Key; RestURL = 'https://jira.example.com/rest/api/2/issue/TEST-1' } }
            $result = Resolve-JiraIssueObject -InputObject ([AtlassianPS.JiraPS.Issue]@{ Key = 'TEST-1' }) -RequestContext $context

            $result.Key | Should -Be 'TEST-1'
            Should -Invoke Get-JiraIssue -Exactly 1 -ParameterFilter {
                $Issue.Key -eq 'TEST-1' -and [Object]::ReferenceEquals($Connection, $script:context) -and
                $Connection.GetAuthorizationHeader() -eq 'Bearer override-secret' -and $Connection.GetWebSession().Cookies.Count -eq 0
            }
            $source.GetAuthorizationHeader() | Should -Be 'Bearer source-secret'
        }

        It 'returns a resolved issue without another request' {
            Mock Get-JiraIssue { throw 'Unexpected issue lookup.' }
            $issue = [AtlassianPS.JiraPS.Issue]@{ Key = 'TEST-1'; RestURL = 'https://jira.example.com/rest/api/2/issue/TEST-1' }

            [Object]::ReferenceEquals((Resolve-JiraIssueObject -InputObject $issue -RequestContext $context), $issue) | Should -BeTrue
            Should -Invoke Get-JiraIssue -Times 0
        }
    }
}
