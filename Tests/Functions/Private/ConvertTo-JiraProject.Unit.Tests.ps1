#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraProject" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:projectKey = 'IT'
            $script:projectId = '10003'
            $script:projectName = 'Information Technology'

            $script:sampleJson = @"
{
    "expand": "description,lead,url,projectKeys",
    "self": "$jiraServer/rest/api/2/project/$projectId",
    "id": "$projectId",
    "key": "$projectKey",
    "name": "$projectName",
    "description": "",
    "lead": {
        "self":  "$jiraServer/rest/api/2/user?username=admin",
        "key": "admin",
        "name": "admin",
        "avatarUrls": {
            "48x48": "$jiraServer/secure/useravatar?ownerId=admin\u0026avatarId=10903",
            "24x24": "$jiraServer/secure/useravatar?size=small\u0026ownerId=admin\u0026avatarId=10903",
            "16x16": "$jiraServer/secure/useravatar?size=xsmall\u0026ownerId=admin\u0026avatarId=10903",
            "32x32": "$jiraServer/secure/useravatar?size=medium\u0026ownerId=admin\u0026avatarId=10903"
        },
        "displayName": "Admin",
        "active": true
    },
    "url": "$jiraServer/browse/HCC/",
    "avatarUrls": {
        "48x48": "$jiraServer/secure/projectavatar?pid=16802\u0026avatarId=10011",
        "24x24": "$jiraServer/secure/projectavatar?size=small\u0026pid=16802\u0026avatarId=10011",
        "16x16": "$jiraServer/secure/projectavatar?size=xsmall\u0026pid=16802\u0026avatarId=10011",
        "32x32": "$jiraServer/secure/projectavatar?size=medium\u0026pid=16802\u0026avatarId=10011"
    },
    "projectKeys": "HCC",
    "projectCategory": {
        "self": "$jiraServer/rest/api/2/projectCategory/10000",
        "id":  "10000",
        "name":  "Home Connect",
        "description":  "Home Connect Projects"
    },
    "projectTypeKey": "software",
    "components": {
        "self": "$jiraServer/rest/api/2/component/11000",
        "id": "11000",
        "description": "A test component",
        "name": "test component"
    }
}
"@
            $script:sampleObject = ConvertFrom-Json -InputObject $sampleJson
            #endregion Definitions

            #region Mocks
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "Object Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraProject -InputObject $sampleObject
                }

                It "creates PSObject from JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                }

                It "adds custom type 'JiraPS.Project'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'JiraPS.Project'
                }
            }

            Context "Property Mapping" {
                BeforeAll {
                    $script:result = ConvertTo-JiraProject -InputObject $sampleObject
                }

                It "defines 'Id' property with correct value" {
                    $result.Id | Should -Be $projectId
                }

                It "defines 'Key' property with correct value" {
                    $result.Key | Should -Be $projectKey
                }

                It "defines 'Name' property with correct value" {
                    $result.Name | Should -Be $projectName
                }

                It "defines 'RestUrl' property with correct value" {
                    $result.RestUrl | Should -Be "$jiraServer/rest/api/2/project/$projectId"
                }
            }

            Context "Type Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraProject -InputObject $sampleObject
                }

                It "converts Lead to JiraPS.User type" {
                    $result.Lead.PSObject.TypeNames[0] | Should -Be 'JiraPS.User'
                }
            }

            Context "Pipeline Support" {
                It "accepts pipeline input" {
                    $result = $sampleObject | ConvertTo-JiraProject
                    $result | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}
