. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'

    $issueLinkId = 1234

    # We don't care about anything except for the id
    $resultsJson = @"
{
    "id": "$issueLinkId",
    "self": "",
    "type": {},
    "inwardIssue": {},
    "outwardIssue": {}
}
"@

    Describe "Remove-JiraIssueLink" {
        $showMockData = $true
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Delete' -and $URI -eq "$jiraServer/rest/api/latest/issueLink/1234"} {
            return $null
        }

        Mock Get-JiraIssue -ModuleName JiraPS -ParameterFilter {$Key -eq "TEST-01"} {
            # We don't care about the content of any field except for the id of the issuelinks
            $obj = [PSCustomObject]@{
                "id"          = $issueLinkId
                "type"        = "foo"
                "inwardIssue" = "bar"
            }
            $obj.PSObject.TypeNames.Insert(0, 'JiraPS.IssueLink')
            $issue = [PSCustomObject]@{
                issueLinks = @(
                    $obj
                )
            }
            $issue.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            return $issue
        }

        Mock Get-JiraIssueLink -ModuleName JiraPS {
            $obj = [PSCustomObject]@{
                "id"          = $issueLinkId
                "type"        = "foo"
                "inwardIssue" = "bar"
            }
            $obj.PSObject.TypeNames.Insert(0, 'JiraPS.IssueLink')
            return $obj
        }

        #############
        # Tests
        #############

        Context "Sanity checking" {
            $command = Get-Command -Name Remove-JiraIssueLink

            defParam $command 'IssueLink'
            defParam $command 'Credential'
        }

        Context "Functionality" {


            It "Accepts generic object with the correct properties" {
                $issueLink = [PSCustomObject]@{ id = $issueLinkId }
                { Remove-JiraIssueLink -IssueLink $issueLink } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
            }

            It "Accepts a JiraPS.Issue object over the pipeline" {
                { Get-JiraIssue -Key TEST-01 | Remove-JiraIssueLink } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
            }

            It "Accepts a JiraPS.IssueType over the pipeline" {
                { Get-JiraIssueLink -Id 1234 | Remove-JiraIssueLink  } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
            }

            It "Validates pipeline input" {
                { @{id = 1} | Remove-JiraIssueLink } | Should Throw
            }
        }
    }
}
