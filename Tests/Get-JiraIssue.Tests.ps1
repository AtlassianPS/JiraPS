Describe "Get-JiraIssue" {

    Import-Module "$PSScriptRoot/../JiraPS" -Force -ErrorAction Stop

    InModuleScope JiraPS {

        . "$PSScriptRoot/Shared.ps1"

        $jiraServer = "https://jira.example.com"

        $jql = 'reporter in (testuser)'
        $jqlEscaped = ConvertTo-URLEncoded $jql
        $response = @'
{
    "expand": "schema,names",
    "startAt": 0,
    "maxResults": 25,
    "total": 1,
    "issues": [
        {
            "key": "TEST-001",
            "fields": {
                "summary": "Test summary"
            }
        }
    ]
}
'@

        Mock Get-JiraConfigServer {
            $jiraServer
        }

        Mock Invoke-JiraMethod -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/latest/issue/TEST-001*" } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json2 $response
        }

        Mock Invoke-JiraMethod -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/latest/search?jql=$jqlEscaped*" } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json2 $response
        }

        Mock Invoke-JiraMethod {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        Mock Get-JiraUser {
            $object = [PSCustomObject] @{
                'Name' = 'username'
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.User')
            return $object
        }

        Context "Sanity checking" {
            $command = Get-Command -Name Get-JiraIssue

            defParam $command 'Key'
            defParam $command 'InputObject'
            defParam $command 'Query'
            defParam $command 'Filter'
            defParam $command 'StartIndex'
            defParam $command 'MaxResults'
            defParam $command 'PageSize'
            defParam $command 'Credential'
        }

        Context "Behavior testing" {

            It "Obtains information about a provided issue in JIRA" {
                { Get-JiraIssue -Key TEST-001 } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like '*/rest/api/*/issue/TEST-001*' }
            }

            It "Uses JQL to search for issues if the -Query parameter is used" {
                { Get-JiraIssue -Query $jql } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like "*/rest/api/latest/search?jql=$jqlEscaped*" }
            }

            It "Supports the -StartIndex and -MaxResults parameters to page through search results" {
                { Get-JiraIssue -Query $jql -StartIndex 10 -MaxResults 50 } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like "*/rest/api/latest/search?jql=$jqlEscaped*startAt=10&maxResults=50*" }
            }

            It "Returns all issues via looping if -MaxResults is not specified" {
                { Get-JiraIssue -Query $jql -PageSize 25 } | Should Not Throw

                # This should call Invoke-JiraMethod once for one issue (to get the MaxResults value)...
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like "*/rest/api/latest/search?jql=$jqlEscaped*maxResults=1*" }

                # ...and once more with the MaxResults set to the PageSize parameter
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like "*/rest/api/latest/search?jql=$jqlEscaped*startAt=0&maxResults=25" }
            }
        }

        Context "Input testing" {
            It "Accepts an issue key for the -Key parameter" {
                { Get-JiraIssue -Key TEST-001 } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like '*/rest/api/*/issue/TEST-001*' }
            }

            It "Accepts an issue object for the -InputObject parameter" {
                $issue = [PSCustomObject] @{
                    'Key' = 'TEST-001'
                    'ID'  = '12345'
                }
                $issue.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')

                # Should call Get-JiraIssue using the -Key parameter, so our URL should reflect the key we provided
                { Get-JiraIssue -InputObject $Issue } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Times 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like '*/rest/api/*/issue/TEST-001*' }
            }
        }
    }
}
