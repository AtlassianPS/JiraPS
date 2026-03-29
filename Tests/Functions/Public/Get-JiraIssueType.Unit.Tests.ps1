#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Get-JiraIssueType" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:issueTypeId = 2
            $script:issueTypeName = 'Desktop Support'

            $script:restResult = @"
[
    {
        "self": "$jiraServer/rest/api/2/issuetype/12",
        "id": "12",
        "description": "This issue type is no longer used.",
        "iconUrl": "$jiraServer/images/icons/issuetypes/delete.png",
        "name": "ZZ_DO_NOT_USE",
        "subtask": false
    },
    {
        "self": "$jiraServer/rest/api/2/issuetype/11",
        "id": "11",
        "description": "An issue related to classroom technology, moodle, library services",
        "iconUrl": "$jiraServer/images/icons/issuetypes/documentation.png",
        "name": "Educational Technology Services",
        "subtask": false
    },
    {
        "self": "$jiraServer/rest/api/2/issuetype/4",
        "id": "4",
        "description": "An issue related to network connectivity or infrastructure including Access Control.",
        "iconUrl": "$jiraServer/images/icons/issuetypes/improvement.png",
        "name": "Network Services",
        "subtask": false
    },
    {
        "self": "$jiraServer/rest/api/2/issuetype/6",
        "id": "6",
        "description": "An issue related to telephone services",
        "iconUrl": "$jiraServer/images/icons/issuetypes/genericissue.png",
        "name": "Telephone Services",
        "subtask": false
    },
    {
        "self": "$jiraServer/rest/api/2/issuetype/8",
        "id": "8",
        "description": "An issue related to A/V and media services including teacher stations",
        "iconUrl": "$jiraServer/images/icons/issuetypes/genericissue.png",
        "name": "A/V-Media Services",
        "subtask": false
    },
    {
        "self": "$jiraServer/rest/api/2/issuetype/1",
        "id": "1",
        "description": "An issue related to Banner, MU Online, Oracle Reports, MU Account Suite, Hobsons, or CS Gold",
        "iconUrl": "$jiraServer/images/icons/issuetypes/bug.png",
        "name": "Administrative System",
        "subtask": false
    },
    {
        "self": "$jiraServer/rest/api/2/issuetype/10",
        "id": "10",
        "description": "The sub-task of the issue",
        "iconUrl": "$jiraServer/images/icons/issuetypes/subtask_alternate.png",
        "name": "Sub-task",
        "subtask": true
    },
    {
        "self": "$jiraServer/rest/api/2/issuetype/2",
        "id": "2",
        "description": "An issue related to end-user workstations.",
        "iconUrl": "$jiraServer/images/icons/issuetypes/newfeature.png",
        "name": "Desktop Support",
        "subtask": false
    }
]
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock ConvertTo-JiraIssueType {
                Write-MockDebugInfo 'ConvertTo-JiraIssueType'
                $inputObject
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $Uri -eq "$jiraServer/rest/api/2/issuetype" } {
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
            It "Gets all issue types in Jira if called with no parameters" {
                $allResults = Get-JiraIssueType
                $allResults | Should -Not -BeNullOrEmpty
                @($allResults) | Should -HaveCount 8
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1
            }

            It "Gets a specified issue type if an issue type ID is provided" {
                $oneResult = Get-JiraIssueType -IssueType $issueTypeId
                $oneResult | Should -Not -BeNullOrEmpty
                $oneResult.ID | Should -Be $issueTypeId
                $oneResult.Name | Should -Be $issueTypeName
            }

            It "Gets a specified issue type if an issue type name is provided" {
                $oneResult = Get-JiraIssueType -IssueType $issueTypeName
                $oneResult | Should -Not -BeNullOrEmpty
                $oneResult.ID | Should -Be $issueTypeId
                $oneResult.Name | Should -Be $issueTypeName
            }

            It "Handles positional parameters correctly" {
                $oneResult = Get-JiraIssueType 'Desktop Support'
                $oneResult | Should -Not -BeNullOrEmpty
                $oneResult.ID | Should -Be 2
                $oneResult.Name | Should -Be 'Desktop Support'
            }

            It "Uses ConvertTo-JiraIssueType to beautify output" {
                Get-JiraIssueType
                Should -Invoke ConvertTo-JiraIssueType
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
