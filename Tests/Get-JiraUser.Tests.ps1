. $PSScriptRoot\Shared.ps1

InModuleScope PSJira {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'

    $testUsername = 'powershell-test'
    $testEmail = "$testUsername@example.com"

    $testGroup1 = 'testGroup1'
    $testGroup2 = 'testGroup2'

    $restResult = @"
[
  {
    "self": "$jiraServer/rest/api/2/user?username=$testUsername",
    "key": "$testUsername",
    "name": "$testUsername",
    "emailAddress": "$testEmail",
    "displayName": "Powershell Test User",
    "active": true
  }
]
"@

    # Removed from JSON: avatarUrls, timeZone
    $restResult2 = @"
{
  "self": "$jiraServer/rest/api/2/user?username=$testUsername",
  "key": "$testUsername",
  "name": "$testUsername",
  "emailAddress": "$testEmail",
  "displayName": "Powershell Test User",
  "active": true,
  "groups": {
    "size": 5,
    "items": [
      {
        "name": "$testGroup1",
        "self": "$jiraServer/rest/api/2/group?groupname=$testGroup1"
      },
      {
        "name": "$testGroup2",
        "self": "$jiraServer/rest/api/2/group?groupname=$testGroup2"
      }
    ]
  },
  "expand": "groups"
}
"@

    Describe "Get-JiraUser" {

        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        # Searching for a user.
        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/user/search?username=$testUsername"} {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-JiraMethod with GET method" -ForegroundColor Cyan
                Write-Host "         [Method] $Method" -ForegroundColor Cyan
                Write-Host "         [URI]    $URI" -ForegroundColor Cyan
            }
            ConvertFrom-Json2 -InputObject $restResult
        }

        # Searching for a user; with paging (first call).
        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/user/search?username=$testUsername&maxResults=50&startAt=0"} {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-JiraMethod with GET method" -ForegroundColor Cyan
                Write-Host "         [Method] $Method" -ForegroundColor Cyan
                Write-Host "         [URI]    $URI" -ForegroundColor Cyan
            }
            ConvertFrom-Json2 -InputObject $restResult
        }

        # Searching for a user; with paging (second call).
        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/user/search?username=$testUsername&maxResults=50&startAt=50"} {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-JiraMethod with GET method" -ForegroundColor Cyan
                Write-Host "         [Method] $Method" -ForegroundColor Cyan
                Write-Host "         [URI]    $URI" -ForegroundColor Cyan
            }
            ConvertFrom-Json2 -InputObject $restResult
        }

        # Viewing a specific user. The main difference here is that this includes groups, and the first does not.
        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/user?username=$testUsername&expand=groups"} {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-JiraMethod with GET method" -ForegroundColor Cyan
                Write-Host "         [Method] $Method" -ForegroundColor Cyan
                Write-Host "         [URI]    $URI" -ForegroundColor Cyan
            }
            ConvertFrom-Json2 -InputObject $restResult2
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

        $getResult = Get-JiraUser -UserName $testUsername

        It "Gets information about a provided Jira user" {
            $getResult | Should Not BeNullOrEmpty
        }

        It "Returns all available properties about the returned user object" {
            $restObj = ConvertFrom-Json2 -InputObject $restResult

            $getResult.RestUrl | Should Be $restObj.self
            $getResult.Name | Should Be $restObj.name
            $getResult.DisplayName | Should Be $restObj.displayName
            $getResult.Active | Should Be $restObj.active
        }

        It "Gets information for a provided Jira user if a PSJira.User object is provided to the InputObject parameter" {
            $result2 = Get-JiraUser -InputObject $getResult
            $result2 | Should Not BeNullOrEmpty
            $result2.Name | Should Be $testUsername
        }

        It "Provides information about the user's group membership in Jira" {
            $getResult.Groups | Should Not BeNullOrEmpty
            $getResult.Groups[0] | Should Be $testGroup1
        }

        Context "Output checking" {
            Mock ConvertTo-JiraUser {}
            Get-JiraUser -Username $testUsername | Out-Null

            It "Uses ConvertTo-JiraUser to beautify output" {
                Assert-MockCalled 'ConvertTo-JiraUser'
            }
        }
    }
}


