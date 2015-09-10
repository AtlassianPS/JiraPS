$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    $ShowMockData = $false
    $ShowDebugData = $false

    $jiraServer = 'http://jiraserver.example.com'

    $testGroupName = 'testGroup'
    
    $testUsername = 'testUsername'
    $testUsername2 = 'testUsername2'

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

    $testJsonUser = @"
{
    "self": "$jiraServer/rest/api/2/user?username=$testUsername",
    "key": "$testUsername",
    "name": "$testUsername",
    "displayName": "$testUsername",
    "emailAddress": "$testUsername@example.com",
    "active": true
}
"@

    $testJsonUser2 = @"
{
    "self": "$jiraServer/rest/api/2/user?username=$testUsername2",
    "key": "$testUsername2",
    "name": "$testUsername2",
    "displayName": "$testUsername2",
    "emailAddress": "$testUsername2@example.com",
    "active": true
}
"@

    Describe "Add-JiraGroupMember" {
        
        Mock Write-Debug -ModuleName PSJira {
            if ($ShowDebugData)
            {
                Write-Host -Object "[DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        Mock Get-JiraGroup -ModuleName PSJira {
            ConvertTo-JiraGroup (ConvertFrom-Json $testJson)
        }

        Mock Get-JiraUser -ModuleName PSJira -ParameterFilter {$UserName -eq $testUsername} {
            ConvertTo-JiraUser (ConvertFrom-Json $testJsonUser)
        }

        Mock Get-JiraUser -ModuleName PSJira -ParameterFilter {$UserName -eq $testUsername2} {
            ConvertTo-JiraUser (ConvertFrom-Json $testJsonUser2)
        }

        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'POST' -and $URI -eq "$jiraServer/rest/api/latest/group/user?groupname=$testGroupName"} {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-JiraMethod with DELETE method" -ForegroundColor Cyan
                Write-Host "         [Method]         $Method" -ForegroundColor Cyan
                Write-Host "         [URI]            $URI" -ForegroundColor Cyan
            }
            # This REST method should produce no output
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
        It "Accepts a group name as a String to the -Group parameter" {
            { Add-JiraGroupMember -Group $testGroupName -User $testUsername } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Accepts a PSJira.Group object to the -Group parameter" {
            $group = Get-JiraGroup -GroupName $testGroupName
            { Add-JiraGroupMember -Group $testGroupName -User $testUsername } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Accepts pipeline input from Get-JiraGroup" {
            { Get-JiraGroup -GroupName $testGroupName | Add-JiraGroupMember -User $testUsername } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Adds a user to a JIRA group if the user is not already a member" {
            { Add-JiraGroupMember -Group $testGroupName -User $testUsername } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Adds multiple users to a JIRA group if they are passed to the -User parameter" {
            { Add-JiraGroupMember -Group $testGroupName -User $testUsername,$testUsername2 } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 2 -Scope It
        }
    }
}