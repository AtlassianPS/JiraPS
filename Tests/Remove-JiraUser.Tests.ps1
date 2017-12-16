. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

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

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraUser -ModuleName JiraPS {
            $object = ConvertFrom-Json2 $testJsonGet
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
            return $object
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'DELETE' -and $URI -eq "$jiraServer/rest/api/latest/user?username=$testUsername"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            # This REST method should produce no output
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        It "Accepts a username as a String to the -User parameter" {
            { Remove-JiraUser -User $testUsername -Force } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Accepts a JiraPS.User object to the -User parameter" {
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
