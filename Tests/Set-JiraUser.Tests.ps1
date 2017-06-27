. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

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

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraUser -ModuleName JiraPS {
            ConvertTo-JiraUser (ConvertFrom-Json2 $restResultGet)
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Put' -and $URI -eq "$jiraServer/rest/api/latest/user?username=$testUsername"} {
            if ($ShowMockData) {
                Write-Host "       Mocked Invoke-JiraMethod with GET method" -ForegroundColor Cyan
                Write-Host "         [Method] $Method" -ForegroundColor Cyan
                Write-Host "         [URI]    $URI" -ForegroundColor Cyan
            }
            ConvertFrom-Json2 $restResultGet
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

        # Mock Write-Debug {
        #     Write-Host "DEBUG: $Message" -ForegroundColor Yellow
        # }

        #############
        # Tests
        #############

        It "Accepts a username as a String to the -User parameter" {
            { Set-JiraUser -User $testUsername -DisplayName $testDisplayNameChanged } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Accepts a JiraPS.User object to the -User parameter" {
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

        It "Outputs a JiraPS.User object if the -PassThru parameter is passed" {
            $output = Set-JiraUser -User $testUsername -DisplayName $testDisplayNameChanged -PassThru
            $output | Should Not BeNullOrEmpty
        }
    }
}
