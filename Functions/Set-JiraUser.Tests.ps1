$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    $showMockData = $false

    $jiraServer = 'http://jiraserver.example.com'

    $testUsername = 'powershell-test'
    $testDisplayName = 'PowerShell Test User'
    $testEmail = "$testUsername@example.com"

    $testDisplayNameChanged = "$testDisplayName Modified"
    $testEmailChanged = "$testUsername@example2.com"

    $restResultGet = @"
{
    "self": "$jiraServer/rest/api/2/user?username=$testUsername",
    "key": "$testUsername",
    "name": "$testUsername",
    "displayName": "$testDisplayName",
    "emailAddress": "$testEmail",
    "active": true
}
"@

    Describe "Set-JiraUser" {

        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        Mock Get-JiraUser -ModuleName PSJira {
            ConvertTo-JiraUser (ConvertFrom-Json $restResultGet)
        }

        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Put' -and $URI -eq "$jiraServer/rest/api/latest/user?username=$testUsername"} {
            if ($ShowMockData)
            {
                Write-Host "       Mocked Invoke-JiraMethod with GET method" -ForegroundColor Cyan
                Write-Host "         [Method] $Method" -ForegroundColor Cyan
                Write-Host "         [URI]    $URI" -ForegroundColor Cyan
            }
            ConvertFrom-Json $restResultGet
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

        It "Accepts a username as a String to the -User parameter" {
            { Set-JiraUser -User $testUsername -DisplayName $testDisplayNameChanged } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Accepts a PSJira.User object to the -User parameter" {
            $user = Get-JiraUser -UserName $testUsername
            { Set-JiraUser -User $user -DisplayName $testDisplayNameChanged } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Accepts pipeline input from Get-JiraUser" {
            { Get-JiraUser -UserName $testUsername | Set-JiraUser -DisplayName $testDisplayNameChanged } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Modifies a user's DisplayName if the -DisplayName parameter is passed" {
            # This is not a great test.
            { Set-JiraUser -User $testUsername -DisplayName $testDisplayNameChanged } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Modifies a user's EmailAddress if the -EmailAddress parameter is passed" {
            # Neither is this one.
            { Set-JiraUser -User $testUsername -EmailAddress $testEmailChanged } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Provides no output if the -PassThru parameter is not passed" {
            $output = Set-JiraUser -User $testUsername -DisplayName $testDisplayNameChanged
            $output | Should BeNullOrEmpty
        }

        It "Outputs a PSJira.User object if the -PassThru parameter is passed" {
            $output = Set-JiraUser -User $testUsername -DisplayName $testDisplayNameChanged -PassThru
            $output | Should Not BeNullOrEmpty
        }
    }
}


