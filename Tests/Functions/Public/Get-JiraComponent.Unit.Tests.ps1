#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
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
            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -eq "/rest/api/2/component/$componentId" } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                ConvertFrom-Json $restResultOne
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraRequest -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraRequest"
            }
            #endregion Mocks
        }

        Describe "Behavior" {
            It "Returns details about specific components if the component ID is supplied" {
                $oneResult = Get-JiraComponent -Id $componentId
                $oneResult | Should -Not -BeNullOrEmpty
                @($oneResult) | Should -HaveCount 1
                $oneResult.Id | Should -Be $componentId
            }

        }

    }
}
