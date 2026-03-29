#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Get-JiraServerInformation" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'

            $script:restResult = @"
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
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/2/serverInfo" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $restResult
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            Context "Parameter Types" {
                # TODO: Add parameter type validation tests
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            It "returns the server information" {
                $allResults = Get-JiraServerInformation
                $allResults | Should -Not -BeNullOrEmpty
                @($allResults).Count | Should -Be @(ConvertFrom-Json -InputObject $restResult).Count
            }

            It "answers to the alias 'Get-JiraServerInfo'" {
                $thisAlias = (Get-Alias -Name "Get-JiraServerInfo")
                $thisAlias.ResolvedCommandName | Should -Be "Get-JiraServerInformation"
                $thisAlias.ModuleName | Should -Be "JiraPS"
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
