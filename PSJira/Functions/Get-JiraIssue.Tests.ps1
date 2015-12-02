$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    $ShowMockData = $false
    $ShowDebugText = $false

    Describe "Get-JiraIssue" {
        if ($ShowDebugText)
        {
            Mock "Write-Debug" {
                Write-Host "       [DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        Mock Get-JiraConfigServer {
            'https://jira.example.com'
        }

        # If we don't override this in a context or test, we don't want it to
        # actually try to query a JIRA instance
        Mock Invoke-JiraMethod {}

        Context "Sanity checking" {
            $command = Get-Command -Name Get-JiraIssue

            function defParam($name)
            {
                It "Has a -$name parameter" {
                    $command.Parameters.Item($name) | Should Not BeNullOrEmpty
                }
            }

            defParam 'Key'
            defParam 'InputObject'
            defParam 'Query'
            defParam 'Filter'
            defParam 'StartIndex'
            defParam 'MaxResults'
            defParam 'PageSize'
            defParam 'Credential'
        }

        Context "Behavior testing" {
            Mock Invoke-JiraMethod {
                if ($ShowMockData)
                {
                    Write-Host "       Mocked Invoke-JiraMethod" -ForegroundColor Cyan
                    Write-Host "         [Uri]     $Uri" -ForegroundColor Cyan
                    Write-Host "         [Method]  $Method" -ForegroundColor Cyan
#                    Write-Host "         [Body]    $Body" -ForegroundColor Cyan
                }
            }

            Mock Get-JiraUser {
                [PSCustomObject] @{
                    'Name' = 'username'
                }
            }

            $jql = 'reporter in (testuser)'
            $jqlEscaped = [System.Web.HttpUtility]::UrlPathEncode($jql)

            It "Obtains information about a provided issue in JIRA" {
                { Get-JiraIssue -Key TEST-001 } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Times 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like '*/rest/api/*/issue/TEST-001*' }
            }

            It "Uses JQL to search for issues if the -Query parameter is used" {
                { Get-JiraIssue -Query $jql } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Times 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like "*/rest/api/latest/search?jql=$jqlEscaped*" }
            }

            It "Supports the -StartIndex and -MaxResults parameters to page through search results" {
                { Get-JiraIssue -Query $jql -StartIndex 10 -MaxResults 50 } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Times 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like "*/rest/api/latest/search?jql=$jqlEscaped*startAt=10&maxResults=50*" }
            }

            It "Returns all issues via looping if -MaxResults is not specified" {

                # In order to test this, we'll need a slightly more elaborate
                # mock that actually returns some data.

                Mock Invoke-JiraMethod {
                    if ($ShowMockData)
                    {
                        Write-Host "       Mocked Invoke-JiraMethod" -ForegroundColor Cyan
                        Write-Host "         [Uri]     $Uri" -ForegroundColor Cyan
                        Write-Host "         [Method]  $Method" -ForegroundColor Cyan
#                        Write-Host "         [Body]    $Body" -ForegroundColor Cyan
                    }

                    ConvertFrom-Json @'
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
                }

                { Get-JiraIssue -Query $jql -PageSize 25 } | Should Not Throw

                # This should call Invoke-JiraMethod once for one issue (to get the MaxResults value)...
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Times 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like "*/rest/api/latest/search?jql=$jqlEscaped*maxResults=1*" }

                # ...and once more with the MaxResults set to the PageSize parameter
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Times 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like "*/rest/api/latest/search?jql=$jqlEscaped*startAt=0&maxResults=25" }
            }
        }

        Context "Input testing" {
            It "Accepts an issue key for the -Key parameter" {
                { Get-JiraIssue -Key TEST-001 } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Times 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like '*/rest/api/*/issue/TEST-001*' }
            }

            It "Accepts an issue object for the -InputObject parameter" {
                $issue = [PSCustomObject] @{
                    'Key'     = 'TEST-001'
                    'ID'      = '12345'
                }
                $issue.PSObject.TypeNames.Insert(0, 'PSJira.Issue')

                # Should call Get-JiraIssue using the -Key parameter, so our URL should reflect the key we provided
                { Get-JiraIssue -InputObject $issue } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Times 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like '*/rest/api/*/issue/TEST-001*' }
            }
        }
    }
}
