# PSScriptAnalyzer - ignore creation of a SecureString using plain text for the contents of this script file
# https://replicajunction.github.io/2016/09/19/suppressing-psscriptanalyzer-in-pester/
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    $showMockData = $false

    $jiraServers = @(
        'http://jiraserver.example.com'
        'http://jiraserver2.example.com'
    )
    $authUriEndpoint = '/rest/auth/1/session'
    $authUris = @(
        "$($jiraServers[0])$authUriEndpoint"
        "$($jiraServers[1])$authUriEndpoint"
    )
    $jiraServer = $jiraServers[0]
    $authUri = $authUris[0]
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

    Describe "Remove-JiraSession" {

        function Switch-JiraConfigServer {
            if ($JiraServer -eq $jiraServers[0])
            {
                Set-Variable -Scope 1 -Name JiraServer -Value $jiraServers[1]
            } else {
                Set-Variable -Scope 1 -Name JiraServer -Value $jiraServers[0]
            }
                Set-Variable -Scope 1 -Name authUri -Value "$jiraServer/rest/auth/1/session"
        }

        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        Mock Invoke-WebRequest -Verifiable -ParameterFilter {$authUris -contains $Uri -and $Method -eq 'POST'} {
            if ($showMockData)
            {
                Write-Host "       Mocked Invoke-WebRequest with POST method" -ForegroundColor Cyan
                Write-Host "         [Method]         $Method" -ForegroundColor Cyan
                Write-Host "         [URI]            $URI" -ForegroundColor Cyan
            }
            $global:newSessionVar = @{}
            Write-Output $testJson
        }

        Mock Invoke-WebRequest -Verifiable -ParameterFilter {$authUris -contains $Uri -and $Method -eq 'DELETE'} {
            if ($showMockData)
            {
                Write-Host "       Mocked Invoke-WebRequest with DELETE method" -ForegroundColor Cyan
                Write-Host "         [Method]         $Method" -ForegroundColor Cyan
                Write-Host "         [URI]            $URI" -ForegroundColor Cyan
            }
        }

        Mock Invoke-WebRequest {
            Write-Host "       Mocked Invoke-WebRequest with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

        It "Closes a saved PSJira.Session object from module PrivateData" {

            # This probably isn't the best test for this, but it's about all I can come up with at the moment.
            # New-JiraSession has some slightly more elaborate testing, which includes a test for Get-JiraSession,
            # so if both of those pass, they should work as expected here.

            New-JiraSession -Credential $testCredential | Remove-JiraSession

            Get-JiraSession | Should BeNullOrEmpty
        }

        It "Correctly handles pipeline input from New-JiraSession" {
            { New-JiraSession -Credential $testCredential | Remove-JiraSession } | Should Not Throw
            Get-JiraSession | Should BeNullOrEmpty
            Assert-MockCalled -CommandName Invoke-WebRequest -ParameterFilter {$Uri -eq $authUri -and $Method -eq 'DELETE'} -Exactly -Times 1 -Scope It
        }

        It "Correctly handles pipeline input from Get-JiraSession" {
            New-JiraSession -Credential $testCredential
            { Get-JiraSession | Remove-JiraSession } | Should Not Throw
            Get-JiraSession | Should BeNullOrEmpty
            Assert-MockCalled -CommandName Invoke-WebRequest -ParameterFilter {$Uri -eq $authUri -and $Method -eq 'DELETE'} -Exactly -Times 1 -Scope It
        }

        It "Removes all sessions" {
            New-JiraSession -Credential $testCredential
            Switch-JiraConfigServer
            New-JiraSession -Credential $testCredential
            {Remove-JiraSession -All } | Should Not Throw
            Get-JiraSession | Should BeNullOrEmpty
            Assert-MockCalled -CommandName Invoke-WebRequest -ParameterFilter {$authUris -contains $Uri -and $Method -eq 'DELETE'} -Exactly -Times 2 -Scope It
        }

    }
}


