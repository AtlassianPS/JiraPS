#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Remove-JiraRemoteLink" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:testIssueKey = 'EX-1'

            $script:testLink = @"
{
    "id": 10000,
    "self": "http://www.example.com/jira/rest/api/issue/MKY-1/remotelink/10000",
    "globalId": "system=http://www.mycompany.com/support&id=1",
    "application": {
        "type": "com.acme.tracker",
        "name": "My Acme Tracker"
    },
    "relationship": "causes",
    "object": {
        "url": "http://www.mycompany.com/support?id=1",
        "title": "TSTSUP-111",
        "summary": "Crazy customer support issue",
        "icon": {
            "url16x16": "http://www.mycompany.com/support/ticket.png",
            "title": "Support Ticket"
        }
    }
}
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraIssue {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                $object = [AtlassianPS.JiraPS.Issue]@{
                    RestURL = 'https://jira.example.com/rest/api/2/issue/12345'
                    Key     = $testIssueKey
                }
                return $object
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'InputObject'
                Get-JiraIssue -Key $InputObject.Key
            }

            Mock Get-JiraRemoteLink {
                Write-MockDebugInfo 'Get-JiraRemoteLink' 'Issue'
                $object = ConvertFrom-Json $testLink
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.IssueLinkType')
                return $object
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter { $Method -eq 'DELETE' } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                # This REST method should produce no output
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraRequest -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraRequest"
            }
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "Remote Link Deletion" {
                It "Accepts a issue key to the -Issue parameter" {
                    { Remove-JiraRemoteLink -Issue $testIssueKey -Link 10000 -Confirm:$false } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraRequest -Exactly -Times 1
                }

                It "Accepts a AtlassianPS.JiraPS.Issue object to the -Issue parameter" {
                    $Issue = Get-JiraIssue $testIssueKey
                    { Remove-JiraRemoteLink -Issue $Issue -Link 10000 -Confirm:$false } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraRequest -Exactly -Times 1
                }

                It "Accepts pipeline input from Get-JiraIssue" {
                    { Get-JiraIssue $testIssueKey | Remove-JiraRemoteLink -Link 10000 -Confirm:$false } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraRequest -Exactly -Times 1
                }

                It "Accepts the output of Get-JiraRemoteLink" {
                    $issue = [AtlassianPS.JiraPS.Issue]@{ Key = $testIssueKey }
                    $remoteLink = Get-JiraRemoteLink $issue
                    { Remove-JiraRemoteLink -Issue $issue -Link $remoteLink.id -Confirm:$false } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraRequest -Exactly -Times 1
                }

                It "Provides no output" {
                    Remove-JiraRemoteLink -Issue $testIssueKey -Link 10000 -Confirm:$false | Should -BeNullOrEmpty
                }
            }
        }

    }
}
