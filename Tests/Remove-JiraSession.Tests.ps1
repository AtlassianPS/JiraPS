# PSScriptAnalyzer - ignore creation of a SecureString using plain text for the contents of this script file
# https://replicajunction.github.io/2016/09/19/suppressing-psscriptanalyzer-in-pester/
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'
    $authUri = "$jiraServer/rest/api/2/mypermissions"
    $sessionUri = "$jiraServer/rest/auth/1/session"
    $jSessionId = '76449957D8C863BE8D4F6F5507E980E8'

    $testUsername = 'powershell-test'
    $testPassword = ConvertTo-SecureString -String 'test123' -AsPlainText -Force
    $testCredential = New-Object -TypeName PSCredential -ArgumentList $testUsername, $testPassword

    $testJson = @"
{
    "session": {
        "name": "JSESSIONID",
        "value": "$jSessionId"
    },
    "loginInfo": {
        "failedLoginCount": 5,
        "loginCount": 10,
        "lastFailedLoginTime": "2015-06-23T13:17:44.005-0500",
        "previousLoginTime": "2015-06-23T10:22:03.514-0500"
    }
}
"@

    Describe "Remove-JiraSession" {

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Invoke-WebRequest -Verifiable -ParameterFilter {$Uri -eq $authUri -and $Method -eq 'GET'} {
            if ($showMockData) {
                Write-Output "       Mocked Invoke-WebRequest with GET method" -ForegroundColor Cyan
                Write-Output "         [Method]         $Method" -ForegroundColor Cyan
                Write-Output "         [URI]            $URI" -ForegroundColor Cyan
            }
            $global:newSessionVar = @{}
            Write-Output $testJson
        }

        Mock Invoke-WebRequest -Verifiable -ParameterFilter {$Uri -eq $sessionUri -and $Method -eq 'DELETE'} {
            if ($showMockData) {
                Write-Output "       Mocked Invoke-WebRequest with DELETE method" -ForegroundColor Cyan
                Write-Output "         [Method]         $Method" -ForegroundColor Cyan
                Write-Output "         [URI]            $URI" -ForegroundColor Cyan
            }
        }

        Mock Invoke-WebRequest {
            Write-Output "       Mocked Invoke-WebRequest with no parameter filter." -ForegroundColor DarkRed
            Write-Output "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Output "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

        It "Closes a saved JiraPS.Session object from module PrivateData" {

            # This probably isn't the best test for this, but it's about all I can come up with at the moment.
            # New-JiraSession has some slightly more elaborate testing, which includes a test for Get-JiraSession,
            # so if both of those pass, they should work as expected here.

            New-JiraSession -Credential $testCredential
            Get-JiraSession | Should Not BeNullOrEmpty

            Remove-JiraSession
            Get-JiraSession | Should BeNullOrEmpty
            Assert-MockCalled -CommandName Invoke-WebRequest -ParameterFilter {$Uri -eq $sessionUri -and $Method -eq 'DELETE'} -Exactly -Times 1 -Scope It
        }

        It "Correctly handles sessions from a variable" {
            $Session = New-JiraSession -Credential $testCredential
            $Session | Should Not BeNullOrEmpty
            Get-JiraSession | Should Not BeNullOrEmpty

            Remove-JiraSession $Session
            Get-JiraSession | Should BeNullOrEmpty
            Assert-MockCalled -CommandName Invoke-WebRequest -ParameterFilter {$Uri -eq $sessionUri -and $Method -eq 'DELETE'} -Exactly -Times 1 -Scope It
        }

        It "Correctly handles pipeline input from New-JiraSession" {
            { New-JiraSession -Credential $testCredential | Remove-JiraSession } | Should Not Throw
            Get-JiraSession | Should BeNullOrEmpty
            Assert-MockCalled -CommandName Invoke-WebRequest -ParameterFilter {$Uri -eq $sessionUri -and $Method -eq 'DELETE'} -Exactly -Times 1 -Scope It
        }

        It "Correctly handles pipeline input from Get-JiraSession" {
            New-JiraSession -Credential $testCredential
            { Get-JiraSession | Remove-JiraSession } | Should Not Throw
            Get-JiraSession | Should BeNullOrEmpty
            Assert-MockCalled -CommandName Invoke-WebRequest -ParameterFilter {$Uri -eq $sessionUri -and $Method -eq 'DELETE'} -Exactly -Times 1 -Scope It
        }
    }
}
