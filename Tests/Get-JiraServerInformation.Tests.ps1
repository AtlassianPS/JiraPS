. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    $jiraServer = 'http://jiraserver.example.com'

    $restResult = @"
{
    "baseUrl":"$jiraServer",
    "version":"1000.1323.0",
    "versionNumbers":[1000,1323,0],
    "deploymentType":"Cloud",
    "buildNumber":100062,
    "buildDate":"2017-09-26T00:00:00.000+0200",
    "serverTime":"2017-09-27T09:59:25.520+0200",
    "scmInfo":"f3c60100df073e3576f9741fb7a3dc759b416fde",
    "serverTitle":"JIRA"
}
"@

    Describe "Get-JiraServerInformation" {
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/latest/serverInfo"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json2 $restResult
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        It "Returns the server information" {
            $allResults = Get-JiraServerInformation
            $allResults | Should Not BeNullOrEmpty
            @($allResults).Count | Should Be @(ConvertFrom-Json2 -InputObject $restResult).Count
        }

        It "Answers to the alias 'Get-JiraServerInfo'" {
            $thisAlias = (Get-Alias -Name "Get-JiraServerInfo")
            $thisAlias.ResolvedCommandName | Should Be "Get-JiraServerInformation"
            $thisAlias.Source | Should Be "JiraPS"
        }
    }
}
