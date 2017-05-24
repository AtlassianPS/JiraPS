# PSScriptAnalyzer - ignore creation of a SecureString using plain text for the contents of this script file
# https://replicajunction.github.io/2016/09/19/suppressing-psscriptanalyzer-in-pester/
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

. $PSScriptRoot\Shared.ps1

InModuleScope PSJira {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'
    $authUri = "$jiraServer/rest/auth/1/session"
    $jSessionId = '76449957D8C863BE8D4F6F5507E980E8'

    $testUsername = 'powershell-test'
    $testPassword = ConvertTo-SecureString -String 'test123' -AsPlainText -Force
    $testCredential = New-Object -TypeName PSCredential -ArgumentList $testUsername,$testPassword


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
    Describe "New-JiraSession" {

        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        Mock Invoke-WebRequest -Verifiable -ParameterFilter {$Uri -eq $authUri -and $Method -eq 'POST'} {
            if ($showMockData)
            {
                Write-Host "       Mocked Invoke-WebRequest with POST method" -ForegroundColor Cyan
                Write-Host "         [Method]         $Method" -ForegroundColor Cyan
                Write-Host "         [URI]            $URI" -ForegroundColor Cyan
            }
            $global:newSessionVar = @{}
            Write-Output $testJson
        }

        Mock Invoke-WebRequest {
            Write-Host "       Mocked Invoke-WebRequest with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
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


