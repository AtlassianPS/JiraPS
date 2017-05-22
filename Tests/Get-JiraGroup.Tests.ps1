. $PSScriptRoot\Shared.ps1

InModuleScope PSJira {

    $showMockData = $false

    $jiraServer = 'http://jiraserver.example.com'

    $testGroupName = 'Test Group'
    $testGroupNameEscaped = [System.Web.HttpUtility]::UrlPathEncode($testGroupName)
    $testGroupSize = 1

    $restResult = @"
{
  "name": "$testGroupName",
  "self": "$jiraServer/rest/api/2/group?groupname=$testGroupName",
  "users": {
    "size": $testGroupSize,
    "items": [],
    "max-results": 50,
    "start-index": 0,
    "end-index": 0
  },
  "expand": "users"
}
"@

    Describe "Get-JiraGroup" {

        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        # Searching for a group.
        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/latest/group?groupname=$testGroupNameEscaped"} {
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

        Mock ConvertTo-JiraGroup { $InputObject }

#        Mock Write-Debug {
#            Write-Host "DEBUG: $Message" -ForegroundColor Yellow
#        }

        #############
        # Tests
        #############

        It "Gets information about a provided Jira group" {
            $getResult = Get-JiraGroup -GroupName $testGroupName
            $getResult | Should Not BeNullOrEmpty
        }

        It "Uses ConvertTo-JiraGroup to beautify output" {
            Assert-MockCalled 'ConvertTo-JiraGroup'
        }
    }
}


