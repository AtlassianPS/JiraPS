#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Get-JiraProject" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:projectKey = 'IT'
            $script:projectId = '10003'
            $script:projectName = 'Information Technology'
            $script:projectKey2 = 'TEST'
            $script:projectId2 = '10004'
            $script:projectName2 = 'Test Project'

            $script:restResultAll = @"
[
    {
        "self": "$jiraServer/rest/api/2/project/10003",
        "id": "$projectId",
        "key": "$projectKey",
        "name": "$projectName",
        "projectCategory": {
            "self": "$jiraServer/rest/api/2/projectCategory/10000",
            "id": "10000",
            "description": "All Project Catagories",
            "name": "All Project"
        }
    },
    {
        "self": "$jiraServer/rest/api/2/project/10121",
        "id": "$projectId2",
        "key": "$projectKey2",
        "name": "$projectName2",
        "projectCategory": {
            "self": "$jiraServer/rest/api/2/projectCategory/10000",
            "id": "10000",
            "description": "All Project Catagories",
            "name": "All Project"
        }
    }
]
"@

            $script:restResultOne = @"
[
    {
        "self": "$jiraServer/rest/api/2/project/10003",
        "id": "$projectId",
        "key": "$projectKey",
        "name": "$projectName",
        "projectCategory": {
            "self": "$jiraServer/rest/api/2/projectCategory/10000",
            "id": "10000",
            "description": "All Project Catagories",
            "name": "All Project"
        }
    }
]
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/project*" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $restResultAll
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/project/$projectKey?*" } {
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
            It "Returns all projects if called with no parameters" {
                $allResults = Get-JiraProject
                $allResults | Should -Not -BeNullOrEmpty
                @($allResults).Count | Should -Be (ConvertFrom-Json -InputObject $restResultAll).Count
            }

            It "Returns details about specific projects if the project key is supplied" {
                $oneResult = Get-JiraProject -Project $projectKey
                $oneResult | Should -Not -BeNullOrEmpty
                @($oneResult) | Should -HaveCount 1
            }

            It "Returns details about specific projects if the project ID is supplied" {
                $oneResult = Get-JiraProject -Project $projectId
                $oneResult | Should -Not -BeNullOrEmpty
                @($oneResult) | Should -HaveCount 1
            }

            It "Provides the key of the project" {
                $oneResult = Get-JiraProject -Project $projectKey
                $oneResult.Key | Should -Be $projectKey
            }

            It "Provides the ID of the project" {
                $oneResult = Get-JiraProject -Project $projectKey
                $oneResult.Id | Should -Be $projectId
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
