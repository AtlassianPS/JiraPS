$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {
    
    $showMockData = $false

    $jiraServer = 'http://jiraserver.example.com'

    $testUsername = 'powershell-test'
    $testEmail = "$testUsername@example.com"

    $testGroupName = 'Test Group'
    $testGroupNameEscaped = [System.Web.HttpUtility]::UrlPathEncode($testGroupName)
    $testGroupSize = 1

    $restResultNoUsers = @"
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

    $restResultWithUsers = @"
{
  "name": "$testGroupName",
  "self": "$jiraServer/rest/api/2/group?groupname=$testGroupName",
  "users": {
    "size": $testGroupSize,
    "items": [
        {
            "self": "$jiraServer/rest/api/2/user?username=$testUsername",
            "key": "$testUsername",
            "name": "$testUsername",
            "emailAddress": "$testEmail",
            "displayName": "Powershell Test User",
            "active": true
        }
    ],
    "max-results": 50,
    "start-index": 0,
    "end-index": 0
  },
  "expand": "users"
}
"@

    Describe "Get-JiraGroupMember" {

        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        # This is called by Get-JiraGroup - no users provided
        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/latest/group?groupname=$testGroupNameEscaped"} {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-JiraMethod with GET method" -ForegroundColor Cyan
                Write-Host "         [Method] $Method" -ForegroundColor Cyan
                Write-Host "         [URI]    $URI" -ForegroundColor Cyan
            }
            ConvertFrom-Json -InputObject $restResultNoUsers
        }

        # This is called by Get-JiraGroupMember - user information included
        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/latest/group?groupname=$testGroupNameEscaped&expand=users"} {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-JiraMethod with GET method" -ForegroundColor Cyan
                Write-Host "         [Method] $Method" -ForegroundColor Cyan
                Write-Host "         [URI]    $URI" -ForegroundColor Cyan
            }
            ConvertFrom-Json -InputObject $restResultWithUsers
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

        It "Returns the members of a given JIRA group" {
            $members = Get-JiraGroupMember -Group $testGroupName
            $members | Should Not BeNullOrEmpty
            $members.Count | Should Be $testGroupSize
        }

        It "Returns results as PSJira.User objects" {
            $members = Get-JiraGroupMember -Group $testGroupName
            (Get-Member -InputObject @($members)[0]).MemberType | Should Be 'PSJira.User'
        }
    }
}