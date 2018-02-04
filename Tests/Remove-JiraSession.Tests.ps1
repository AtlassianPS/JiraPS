Import-Module "$PSScriptRoot/../JiraPS" -Force -ErrorAction Stop

InModuleScope JiraPS {
    . "$PSScriptRoot/Shared.ps1"
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]

    $jiraServer = 'http://jiraserver.example.com'
    $authUri = "$jiraServer/rest/api/*/mypermissions"
    $jSessionId = '76449957D8C863BE8D4F6F5507E980E8'

    $testUsername = 'powershell-test'
    $testPassword = ConvertTo-SecureString -String 'test123' -AsPlainText -Force
    $testCredential = New-Object -TypeName PSCredential -ArgumentList $testUsername, $testPassword

    $testJson = @"
{
}
"@

    Describe "Remove-JiraSession" {

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Invoke-WebRequest -Verifiable -ParameterFilter {$Method -eq 'GET' -and $Uri -like $authUri} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            $global:newSessionVar = @{}
            Write-Output $testJson
        }

        Mock Invoke-WebRequest {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
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
        }

        It "Correctly handles sessions from a variable" {
            $Session = New-JiraSession -Credential $testCredential
            $Session | Should Not BeNullOrEmpty
            Get-JiraSession | Should Not BeNullOrEmpty

            Remove-JiraSession $Session
            Get-JiraSession | Should BeNullOrEmpty
        }

        It "Correctly handles pipeline input from New-JiraSession" {
            { New-JiraSession -Credential $testCredential | Remove-JiraSession } | Should Not Throw
            Get-JiraSession | Should BeNullOrEmpty
        }

        It "Correctly handles pipeline input from Get-JiraSession" {
            New-JiraSession -Credential $testCredential
            { Get-JiraSession | Remove-JiraSession } | Should Not Throw
            Get-JiraSession | Should BeNullOrEmpty
        }
    }
}
