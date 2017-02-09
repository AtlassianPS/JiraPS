$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    $showMockData = $false

    $jiraServer = 'http://jiraserver.example.com'

    $testIssueKey = 'MKY-1'

    $restResult = @"
    {
       "id": 10000,
       "self": "http://jiraserver.example.com/rest/api/issue/MKY-1/remotelink/10000",
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

    Describe "Get-JiraRemoteLink" {

        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        Mock Get-JiraIssue {
            [PSCustomObject] @{
                'RestURL' = 'https://jira.example.com/rest/api/2/issue/12345'
                'Key'     = $testIssueKey
            }
        }

        # Searching for a group.
        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Get'} {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-JiraMethod with GET method" -ForegroundColor Cyan
                Write-Host "         [Method] $Method" -ForegroundColor Cyan
                Write-Host "         [URI]    $URI" -ForegroundColor Cyan
            }
            ConvertFrom-Json2 -InputObject $restResult
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName PSJira {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

#        Mock Write-Debug {
#            Write-Host "DEBUG: $Message" -ForegroundColor Yellow
#        }

        #############
        # Tests
        #############

        It "Gets information of all remote link from a Jira issue" {
            $getResult = Get-JiraRemoteLink -Issue $testIssueKey
            $getResult | Should Not BeNullOrEmpty
        }

        It "Converts the output object to PSJira.Link" {
            $getResult = Get-JiraRemoteLink -Issue $testIssueKey
            (Get-Member -InputObject $getResult).TypeName | Should Be 'PSJira.Link'
        }

        It "Returns all available properties about the returned link object" {
            $getResult = Get-JiraRemoteLink -Issue $testIssueKey
            $restObj = ConvertFrom-Json2 -InputObject $restResult

            $getResult.RestUrl | Should Be $restObj.self
            $getResult.Id | Should Be $restObj.Id
            $getResult.globalId | Should Be $restObj.globalId
        }
    }
}


