#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

Describe "Remove-JiraUser" -Tag 'Unit' {

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

        . "$PSScriptRoot/../Shared.ps1"  # helpers used by tests (defParam / ShowMockInfo)

        $jiraServer = 'http://jiraserver.example.com'

        $testUsername = 'powershell-test'
        $testEmail = "$testUsername@example.com"
        $testDisplayName = 'Test User'

        # Trimmed from this example JSON: expand, groups, avatarURL
        $testJsonGet = @"
{
    "self": "$jiraServer/rest/api/2/user?username=$testUsername",
    "key": "$testUsername",
    "name": "$testUsername",
    "emailAddress": "$testEmail",
    "displayName": "$testDisplayName",
    "active": true
}
"@

        #helper function to generate test JiraIssue object
        function Get-TestJiraUser {
            $object = ConvertFrom-Json $testJsonGet
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.User')
            return $object
        }

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraUser -ModuleName JiraPS {
            Get-TestJiraUser
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'DELETE' -and $URI -like "$jiraServer/rest/api/*/user?username=$testUsername"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            # This REST method should produce no output
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    #############
    # Tests
    #############

    It "Accepts a username as a String to the -User parameter" {
        { Remove-JiraUser -User $testUsername -Force } | Should -Not -Throw
        Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1
    }

    It "Accepts a JiraPS.User object to the -User parameter" {
        $user = Get-TestJiraUser
        { Remove-JiraUser -User $user -Force } | Should -Not -Throw
        Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1
    }

    It "Accepts pipeline input from Get-JiraUser" {
        { Get-TestJiraUser -UserName $testUsername | Remove-JiraUser -Force } | Should -Not -Throw
        Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1
    }

    It "Removes a user from JIRA" {
        { Remove-JiraUser -User $testUsername -Force } | Should -Not -Throw
        Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -Exactly -Times 1
    }

    It "Provides no output" {
        Remove-JiraUser -User $testUsername -Force | Should -BeNullOrEmpty
    }
}
