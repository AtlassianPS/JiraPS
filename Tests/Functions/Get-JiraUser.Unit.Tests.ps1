#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "Get-JiraUser" -Tag 'Unit' {

    BeforeAll {
        Remove-Item -Path Env:\BH*
        $projectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        if ($projectRoot -like "*Release") {
            $projectRoot = (Resolve-Path "$projectRoot/..").Path
        }

        Import-Module BuildHelpers
        Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -Path $projectRoot -ErrorAction SilentlyContinue

        $env:BHManifestToTest = $env:BHPSModuleManifest
        $script:isBuild = $PSScriptRoot -like "$env:BHBuildOutput*"
        if ($script:isBuild) {
            $Pattern = [regex]::Escape($env:BHProjectPath)

            $env:BHBuildModuleManifest = $env:BHPSModuleManifest -replace $Pattern, $env:BHBuildOutput
            $env:BHManifestToTest = $env:BHBuildModuleManifest
        }

        Import-Module "$env:BHProjectPath/Tools/BuildTools.psm1"

        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Import-Module $env:BHManifestToTest
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    InModuleScope JiraPS {

        . "$PSScriptRoot/../Shared.ps1"

        $jiraServer = 'http://jiraserver.example.com'

        $testUsername = 'powershell-test'
        $testEmail = "$testUsername@example.com"

        $testGroup1 = 'testGroup1'
        $testGroup2 = 'testGroup2'

        $restResult = @"
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
        $restResult2 = @"
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

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock ConvertTo-JiraUser -ModuleName JiraPS {
            $InputObject
        }

        # Return information of the current user
        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/myself"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json -InputObject $restResult
        }

        # Searching for a user.
        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/user/search?*username=$testUsername*"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json -InputObject $restResult
        }
        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/user/search?*username=%25*"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json -InputObject $restResult
        }

        # Viewing a specific user. The main difference here is that this includes groups, and the first does not.
        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/user?username=$testUsername&expand=groups"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json -InputObject $restResult2
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        It "Gets intormation about the loged in Jira user" {
            $getResult = Get-JiraUser

            $getResult | Should Not BeNullOrEmpty

            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly 1 -Scope It -ParameterFilter {$URI -like "$jiraServer/rest/api/*/myself"}
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly 1 -Scope It -ParameterFilter {$URI -like "$jiraServer/rest/api/*/user?username=$testUsername&expand=groups"}
        }

        It "Gets information about a provided Jira user" {
            $getResult = Get-JiraUser -UserName $testUsername

            $getResult | Should Not BeNullOrEmpty

            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly 1 -Scope It -ParameterFilter {$URI -like "$jiraServer/rest/api/*/user?username=$testUsername&expand=groups"}
        }

        It "Returns all available properties about the returned user object" {
            $getResult = Get-JiraUser -UserName $testUsername

            $restObj = ConvertFrom-Json -InputObject $restResult

            $getResult.self | Should Be $restObj.self
            $getResult.Name | Should Be $restObj.name
            $getResult.DisplayName | Should Be $restObj.displayName
            $getResult.Active | Should Be $restObj.active

            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly 1 -Scope It -ParameterFilter {$URI -like "$jiraServer/rest/api/*/user?username=$testUsername&expand=groups"}
        }

        It "Gets information for a provided Jira user if a JiraPS.User object is provided to the InputObject parameter" {
            $getResult = Get-JiraUser -UserName $testUsername
            $result2 = Get-JiraUser -InputObject $getResult

            $result2 | Should Not BeNullOrEmpty
            $result2.Name | Should Be $testUsername

            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly 2 -Scope It -ParameterFilter {$URI -like "$jiraServer/rest/api/*/user?username=$testUsername&expand=groups"}
        }

        It "Allow it search for multiple users" {
            Get-JiraUser -UserName "%"

            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly 1 -Scope It -ParameterFilter {
                $URI -like "$jiraServer/rest/api/*/user/search?*username=%25*"
            }
        }

        It "Allows to change the max number of users to be returned" {
            Get-JiraUser -UserName "%" -MaxResults 100

            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly 1 -Scope It -ParameterFilter {
                $URI -like "$jiraServer/rest/api/*/user/search?*maxResults=100*"
            }
        }

        It "Can skip a certain amount of results" {
            Get-JiraUser -UserName "%" -Skip 10

            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly 1 -Scope It -ParameterFilter {
                $URI -like "$jiraServer/rest/api/*/user/search?*startAt=10*"
            }
        }

        It "Provides information about the user's group membership in Jira" {
            $getResult = Get-JiraUser -UserName $testUsername

            $getResult.groups.size | Should Be 2
            $getResult.groups.items[0].Name | Should Be $testGroup1
        }

        Context "Output checking" {
            Get-JiraUser -Username $testUsername | Out-Null

            It "Uses ConvertTo-JiraUser to beautify output" {
                Assert-MockCalled 'ConvertTo-JiraUser'
            }
        }
    }
}
