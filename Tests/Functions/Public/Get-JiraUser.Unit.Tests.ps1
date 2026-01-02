#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Get-JiraUser" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:testUsername = 'powershell-test'
            $script:testEmail = "$testUsername@example.com"
            $script:testGroup1 = 'testGroup1'
            $script:testGroup2 = 'testGroup2'

            $script:restResult = @"
[
    {
        "self": "$jiraServer/rest/api/2/user?username=$testUsername",
        "key": "$testUsername",
        "name": "$testUsername",
        "emailAddress": "$testEmail",
        "displayName": "Powershell Test User",
        "active": true
    }
]
"@

            # Removed from JSON: avatarUrls, timeZone
            $script:restResult2 = @"
{
    "self": "$jiraServer/rest/api/2/user?username=$testUsername",
    "key": "$testUsername",
    "name": "$testUsername",
    "emailAddress": "$testEmail",
    "displayName": "Powershell Test User",
    "active": true,
    "groups": {
        "size": 2,
        "items": [
            {
                "name": "$testGroup1",
                "self": "$jiraServer/rest/api/2/group?groupname=$testGroup1"
            },
            {
                "name": "$testGroup2",
                "self": "$jiraServer/rest/api/2/group?groupname=$testGroup2"
            }
        ]
    },
    "expand": "groups"
}
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock ConvertTo-JiraUser -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraUser'
                $InputObject
            }

            # Return information of the current user
            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/myself" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json -InputObject $restResult
            }

            # Searching for a user.
            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/user/search?*username=$testUsername*" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json -InputObject $restResult
            }
            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/user/search?*username=%25*" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json -InputObject $restResult
            }

            # Get exact user
            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/user?username=$testUsername" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json -InputObject $restResult
            }

            # Viewing a specific user. The main difference here is that this includes groups, and the first does not.
            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/user?username=$testUsername&expand=groups" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json -InputObject $restResult2
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
            It "Gets intormation about the loged in Jira user" {
                $getResult = Get-JiraUser

                $getResult | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -Scope It -ParameterFilter { $URI -like "$jiraServer/rest/api/*/myself" }
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -Scope It -ParameterFilter { $URI -like "$jiraServer/rest/api/*/user?username=$testUsername&expand=groups" }
            }

            It "Gets information about a provided Jira user" {
                $getResult = Get-JiraUser -UserName $testUsername

                $getResult | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -Scope It -ParameterFilter { $URI -like "$jiraServer/rest/api/*/user/search?*username=$testUsername*" }
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -Scope It -ParameterFilter { $URI -like "$jiraServer/rest/api/*/user?username=$testUsername&expand=groups" }
            }

            It "Gets information about a provided Jira exact user" {
                $getResult = Get-JiraUser -UserName $testUsername -Exact

                $getResult | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/user?username=$testUsername" }
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -Scope It -ParameterFilter { $URI -like "$jiraServer/rest/api/*/user?username=$testUsername&expand=groups" }
            }

            It "Returns all available properties about the returned user object" {
                $getResult = Get-JiraUser -UserName $testUsername

                $restObj = ConvertFrom-Json -InputObject $restResult

                $getResult.self | Should -Be $restObj.self
                $getResult.Name | Should -Be $restObj.name
                $getResult.DisplayName | Should -Be $restObj.displayName
                $getResult.Active | Should -Be $restObj.active

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -Scope It -ParameterFilter { $URI -like "$jiraServer/rest/api/*/user?username=$testUsername&expand=groups" }
            }

            It "Gets information for a provided Jira user if a JiraPS.User object is provided to the InputObject parameter" {
                $getResult = Get-JiraUser -UserName $testUsername
                $result2 = Get-JiraUser -InputObject $getResult

                $result2 | Should -Not -BeNullOrEmpty
                $result2.Name | Should -Be $testUsername

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 2 -Scope It -ParameterFilter { $URI -like "$jiraServer/rest/api/*/user?username=$testUsername&expand=groups" }
            }

            It "Allow it search for multiple users" {
                Get-JiraUser -UserName "%"

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -Scope It -ParameterFilter {
                    $URI -like "$jiraServer/rest/api/*/user/search?*username=%25*"
                }
            }

            It "Allows to change the max number of users to be returned" {
                Get-JiraUser -UserName "%" -MaxResults 100

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -Scope It -ParameterFilter {
                    $URI -like "$jiraServer/rest/api/*/user/search?*maxResults=100*"
                }
            }

            It "Can skip a certain amount of results" {
                Get-JiraUser -UserName "%" -Skip 10

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -Scope It -ParameterFilter {
                    $URI -like "$jiraServer/rest/api/*/user/search?*startAt=10*"
                }
            }

            It "Provides information about the user's group membership in Jira" {
                $getResult = Get-JiraUser -UserName $testUsername

                $getResult.groups.size | Should -Be 2
                $getResult.groups.items[0].Name | Should -Be $testGroup1
            }

            Context "Output checking" {
                It "Uses ConvertTo-JiraUser to beautify output" {
                    Get-JiraUser -UserName $testUsername | Out-Null
                    Should -Invoke ConvertTo-JiraUser -ModuleName JiraPS -Exactly 1 -Scope It
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
