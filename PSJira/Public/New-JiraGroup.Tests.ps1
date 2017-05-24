$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    # This is intended to be a parameter to the test, but Pester currently does not allow parameters to be passed to InModuleScope blocks.
    # For the time being, we'll need to hard-code this and adjust it as desired.
    $ShowMockData = $false
    $ShowDebugData = $false

    $jiraServer = 'http://jiraserver.example.com'

    $testGroupName = 'testGroup'

    $testJson = @"
{
  "name": "$testGroupName",
  "self": "$jiraServer/rest/api/2/group?groupname=$testGroupName",
  "users": {
    "size": 0,
    "items": [],
    "max-results": 50,
    "start-index": 0,
    "end-index": 0
  },
  "expand": "users"
}
"@

    Describe "New-JiraGroup" {

        Mock Write-Debug {
            if ($ShowDebugData)
            {
                Write-Host -Object "[DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/latest/group"} {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-JiraMethod with POST method" -ForegroundColor Cyan
                Write-Host "         [Method]         $Method" -ForegroundColor Cyan
                Write-Host "         [URI]            $URI" -ForegroundColor Cyan
            }
            ConvertFrom-Json2 $testJson
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName PSJira {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        It "Creates a group in JIRA and returns a result" {
            $newResult = New-JiraGroup -GroupName $testGroupName
            $newResult | Should Not BeNullOrEmpty
        }

        It "Outputs a PSJira.Group object" {
            $newResult = New-JiraGroup -GroupName $testGroupName
            (Get-Member -InputObject $newResult).TypeName | Should Be 'PSJira.Group'
            $newResult.Name | Should Be $testGroupName
            $newResult.RestUrl | Should Be "$jiraServer/rest/api/2/group?groupname=$testGroupName"
        }
    }
}


