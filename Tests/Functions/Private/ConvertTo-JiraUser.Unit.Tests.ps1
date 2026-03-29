#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraUser" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:username = 'powershell-test'
            $script:displayName = 'PowerShell Test User'
            $script:email = 'noreply@example.com'

            $script:sampleJson = @"
{
    "self":"$jiraServer/rest/api/2/user?username=$username",
    "key":"$username",
    "accountId":"500058:1500a9f1-0000-42b3-0000-ab8900008d00",
    "name":"$username",
    "emailAddress":"$email",
    "avatarUrls":{
        "16x16":"https://avatar-cdn.atlassian.com/a35295e666453af3d0adb689d8da7934?s=16&d=https%3A%2F%2Fsecure.gravatar.com%2Favatar%2Fa35295e666453af3d0adb689d8da7934%3Fd%3Dmm%26s%3D16%26noRedirect%3Dtrue",
        "24x24":"https://avatar-cdn.atlassian.com/a35295e666453af3d0adb689d8da7934?s=24&d=https%3A%2F%2Fsecure.gravatar.com%2Favatar%2Fa35295e666453af3d0adb689d8da7934%3Fd%3Dmm%26s%3D24%26noRedirect%3Dtrue",
        "32x32":"https://avatar-cdn.atlassian.com/a35295e666453af3d0adb689d8da7934?s=32&d=https%3A%2F%2Fsecure.gravatar.com%2Favatar%2Fa35295e666453af3d0adb689d8da7934%3Fd%3Dmm%26s%3D32%26noRedirect%3Dtrue",
        "48x48":"https://avatar-cdn.atlassian.com/a35295e666453af3d0adb689d8da7934?s=48&d=https%3A%2F%2Fsecure.gravatar.com%2Favatar%2Fa35295e666453af3d0adb689d8da7934%3Fd%3Dmm% 26s%3D48%26noRedirect%3Dtrue"
    },
    "displayName":"$displayName",
    "active":true,
    "timeZone":"Europe/Berlin",
    "locale":"en_US",
    "groups":{
        "size":4,
        "items":[
            {
                "name":"administrators",
                "self":"$jiraServer/rest/api/2/group?groupname=administrators"
            },
            {
                "name":"balsamiq-mockups-editors",
                "self":"$jiraServer/rest/api/2/group?groupname=balsamiq-mockups-editors"
            },
            {
                "name":"jira-administrators",
                "self":"$jiraServer/rest/api/2/group?groupname=jira-administrators"
            },
            {
                "name":"site-admins",
                "self":"$jiraServer/rest/api/2/group?groupname=site-admins"
            }
        ]
    },
    "applicationRoles":{
        "size":3,
        "items":[]
    },
    "expand":"groups,applicationRoles"
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
                    $script:result = ConvertTo-JiraUser -InputObject $sampleObject
                }

                It "creates PSObject from JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                }

                It "adds custom type 'JiraPS.User'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'JiraPS.User'
                }
            }

            Context "Property Mapping" {
                BeforeAll {
                    $script:result = ConvertTo-JiraUser -InputObject $sampleObject
                }

                It "defines 'Key' property with correct value" {
                    $result.Key | Should -Be $username
                }

                It "defines 'AccountId' property with correct value" {
                    $result.AccountId | Should -Be "500058:1500a9f1-0000-42b3-0000-ab8900008d00"
                }

                It "defines 'Name' property with correct value" {
                    $result.Name | Should -Be $username
                }

                It "defines 'DisplayName' property with correct value" {
                    $result.DisplayName | Should -Be $displayName
                }

                It "defines 'EmailAddress' property with correct value" {
                    $result.EmailAddress | Should -Be $email
                }

                It "defines 'Active' property with correct value" {
                    $result.Active | Should -Be $true
                }

                It "defines 'RestUrl' property with correct value" {
                    $result.RestUrl | Should -Be "$jiraServer/rest/api/2/user?username=$username"
                }

                It "defines 'AvatarUrl' property" {
                    $result.AvatarUrl | Should -Not -BeNullOrEmpty
                }

                It "defines 'TimeZone' property with correct value" {
                    $result.TimeZone | Should -Be "Europe/Berlin"
                }

                It "defines 'Locale' property with correct value" {
                    $result.Locale | Should -Be "en_Us"
                }

                It "defines 'Groups' property with correct count" {
                    $result.Groups.Count | Should -Be 4
                }
            }

            Context "Type Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraUser -InputObject $sampleObject
                }

                It "converts Active to correct type" {
                    $result.Active | Should -BeOfType [bool]
                }
            }

            Context "Pipeline Support" {
                It "accepts pipeline input" {
                    $result = $sampleObject | ConvertTo-JiraUser
                    $result | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}
