[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

Describe "New-JiraSession" {

Import-Module "$PSScriptRoot/../JiraPS" -Force -ErrorAction Stop

    InModuleScope JiraPS {

        . "$PSScriptRoot/Shared.ps1"

        $jiraServer = 'http://jiraserver.example.com'
        $authUri = "$jiraServer/rest/api/*/mypermissions"

        $testUsername = 'powershell-test'
        $testPassword = ConvertTo-SecureString -String 'test123' -AsPlainText -Force
        $testCredential = New-Object -TypeName PSCredential -ArgumentList $testUsername, $testPassword

        $testJson = "{}"
        $global:newSessionVar = @{}

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Invoke-WebRequest -Verifiable -ParameterFilter {$Method -eq 'Get' -and $Uri -like $authUri} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            Write-Output $testJson
        }

        Mock Invoke-WebRequest {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        It "Invokes a REST method directly to the JIRA server" {
            New-JiraSession -Credential $testCredential
            Assert-MockCalled -CommandName Invoke-WebRequest -Exactly -Times 1 -Scope It
        }

        It "Uses the -UseBasicParsing switch for Invoke-WebRequest" {
            { New-JiraSession -Credential $testCredential } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-WebRequest -ParameterFilter {$UseBasicParsing -eq $true} -Scope It
        }

        It "Provides the JSessionID of the session in Jira" {
            $s = New-JiraSession -Credential $testCredential
            $s.JSessionID | Should Be $jSessionId
        }

        It "Stores the session variable in the module's PrivateData" {
            $s = New-JiraSession -Credential $testCredential
            $s2 = Get-JiraSession
            $s2 | Should Be $s
        }

        Context "Output checking" {
            Mock ConvertTo-JiraSession {}
            New-JiraSession -Credential $testCredential

            It "Uses ConvertTo-JiraSession to beautify output" {
                Assert-MockCalled 'ConvertTo-JiraSession'
            }
        }
    }
}
