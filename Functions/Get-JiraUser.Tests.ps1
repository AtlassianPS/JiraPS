$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    $ShowMockData = $false

    $jiraServer = 'http://jiraserver.example.com'

    $testUsername = 'powershell-test'

    $restResult = @"
[
  {
    "self": "$jiraServer/rest/api/2/user?username=$testUsername",
    "key": "$testUsername",
    "name": "$testUsername",
    "displayName": "Powershell Test User",
    "active": true
  }
]
"@

    Describe "Get-JiraUser" {

        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/latest/user/search?username=$testUsername"} {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-JiraMethod with GET method" -ForegroundColor Cyan
                Write-Host "         [Method] $Method" -ForegroundColor Cyan
                Write-Host "         [URI]    $URI" -ForegroundColor Cyan
            }
            ConvertFrom-Json -InputObject $restResult
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

        It "Gets information about a provided Jira user" {
            $getResult = Get-JiraUser -UserName $testUsername
            $getResult | Should Not BeNullOrEmpty
        }

        It "Converts the output object to PSJira.User" {
            $getResult = Get-JiraUser -UserName $testUsername
            (Get-Member -InputObject $getResult).TypeName | Should Be 'PSJira.User'
        }

        It "Returns all available properties about the returned user object" {
            $getResult = Get-JiraUser -Username $testUsername
            $restObj = ConvertFrom-Json -InputObject $restResult

            $getResult.RestUrl | Should Be $restObj.self
            $getResult.Name | Should Be $restObj.name
            $getResult.DisplayName | Should Be $restObj.displayName
            $getResult.Active | Should Be $restObj.active
        }

        It "Gets information for a provided Jira user if a PSJira.User object is provided to the InputObject parameter" {
            $result1 = Get-JiraUser -Username $testUsername
            $result2 = Get-JiraUser -InputObject $result1
            $result2 | Should Not BeNullOrEmpty
            $result2.Name | Should Be $testUsername
        }
    }
}


