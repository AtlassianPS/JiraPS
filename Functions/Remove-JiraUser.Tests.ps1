$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    # This is intended to be a parameter to the test, but Pester currently does not allow parameters to be passed to InModuleScope blocks.
    # For the time being, we'll need to hard-code this and adjust it as desired.
    $ShowMockData = $false
    $ShowDebugData = $false

    $jiraServer = 'http://jiraserver.example.com'

    $testUsername = 'powershell-test'
    $testEmail = "$testUsername@example.com"
    $testDisplayName = 'Test User'

    # Trimmed from this example JSON: expand, groups, avatarURL
    $testJsonGet = @"
{
    "self": "$jiraServer/rest/api/2/user?username=$testUsername",
    "key": "$testUsername",
    "name": "$testUsername",
    "emailAddress": "$testEmail",
    "displayName": "$testDisplayName",
    "active": true
}
"@

    Describe "Remove-JiraUser" {

        Mock Write-Debug -ModuleName PSJira {
            if ($ShowDebugData)
            {
                Write-Host -Object "[DEBUG] $Message" -ForegroundColor Yellow
            }
        }

        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        Mock Get-JiraUser -ModuleName PSJira {
            ConvertTo-JiraUser (ConvertFrom-Json $testJsonGet)
        }

        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'DELETE' -and $URI -eq "$jiraServer/rest/api/latest/user?username=$testUsername"} {
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

        It "Accepts a username as a String to the -User parameter" {
            { Remove-JiraUser -User $testUsername -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Accepts a PSJira.User object to the -User parameter" {
            $user = Get-JiraUser -UserName $testUsername
            { Remove-JiraUser -User $user -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Accepts pipeline input from Get-JiraUser" {
            { Get-JiraUser -UserName $testUsername | Remove-JiraUser -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Removes a user from JIRA" {
            { Remove-JiraUser -User $testUsername -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Provides no output" {
            Remove-JiraUser -User $testUsername -Force | Should BeNullOrEmpty
        }
    }
}


