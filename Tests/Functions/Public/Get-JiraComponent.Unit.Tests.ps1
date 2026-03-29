#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Get-JiraComponent" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:projectKey = 'TEST'
            $script:projectId = '10004'
            $script:componentId = '10001'
            $script:componentName = 'Component 1'
            $script:componentId2 = '10002'
            $script:componentName2 = 'Component 2'

            $script:restResultAll = @"
[
    {
        "self": "$jiraServer/rest/api/2/component/$componentId",
        "id": "$componentId",
        "name": "$componentName",
        "project": "$projectKey",
        "projectId": "$projectId"
    },
    {
        "self": "$jiraServer/rest/api/2/component/$componentId2",
        "id": "$componentId2",
        "name": "$componentName2",
        "project": "$projectKey",
        "projectId": "$projectId"
    }
]
"@

            $script:restResultOne = @"
[
    {
        "self": "$jiraServer/rest/api/2/component/$componentId",
        "id": "$componentId",
        "name": "$componentName",
        "project": "$projectKey",
        "projectId": "$projectId"
    }
]
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/2/component/$componentId" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $restResultOne
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
            It "Returns details about specific components if the component ID is supplied" {
                $oneResult = Get-JiraComponent -Id $componentId
                $oneResult | Should -Not -BeNullOrEmpty
                @($oneResult) | Should -HaveCount 1
                $oneResult.Id | Should -Be $componentId
            }

            It "Provides the Id of the component" {
                $oneResult = Get-JiraComponent -Id $componentId
                $oneResult.Id | Should -Be $componentId
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
