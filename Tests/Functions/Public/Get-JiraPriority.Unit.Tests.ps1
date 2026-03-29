#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Get-JiraPriority" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'

            $script:restResultAll = @"
[
    {
        "self": "$jiraServer/rest/api/2/priority/1",
        "statusColor": "#cc0000",
        "description": "Cannot continue work. Affects teaching and learning",
        "name": "Critical",
        "id": "1"
    },
    {
        "self": "$jiraServer/rest/api/2/priority/2",
        "statusColor": "#ff0000",
        "description": "High priority, attention needed immediately",
        "name": "High",
        "id": "2"
    },
    {
        "self": "$jiraServer/rest/api/2/priority/3",
        "statusColor": "#ffff66",
        "description": "Typical request for information or service",
        "name": "Normal",
        "id": "3"
    },
    {
        "self": "$jiraServer/rest/api/2/priority/4",
        "statusColor": "#006600",
        "description": "Upcoming project, planned request",
        "name": "Project",
        "id": "4"
    },
    {
        "self": "$jiraServer/rest/api/2/priority/5",
        "statusColor": "#0000ff",
        "description": "General questions, request for enhancement, wish list",
        "name": "Low",
        "id": "5"
    }
]
"@

            $script:restResultOne = @"
{
    "self": "$jiraServer/rest/api/2/priority/1",
    "statusColor": "#cc0000",
    "description": "Cannot continue work. Affects teaching and learning",
    "name": "Critical",
    "id": "1"
}
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock ConvertTo-JiraPriority -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraPriority'
                $InputObject
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/2/priority" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $restResultAll
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/2/priority/1" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $restResultOne
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod {
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
            It "Gets all available priorities if called with no parameters" {
                $getResult = Get-JiraPriority
                $getResult | Should -Not -BeNullOrEmpty
                $getResult | Should -HaveCount 5
            }

            It "Gets one priority if the ID parameter is supplied" {
                $getResult = Get-JiraPriority -Id 1
                $getResult | Should -Not -BeNullOrEmpty
                @($getResult) | Should -HaveCount 1
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
