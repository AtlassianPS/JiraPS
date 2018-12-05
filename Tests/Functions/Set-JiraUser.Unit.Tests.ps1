#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "Set-JiraUser" -Tag 'Unit' {

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
        $testDisplayName = 'PowerShell Test User'
        $testEmail = "$testUsername@example.com"

        $testDisplayNameChanged = "$testDisplayName Modified"
        $testEmailChanged = "$testUsername@example2.com"

        $restResultGet = @"
{
    "self": "$jiraServer/rest/api/2/user?username=$testUsername",
    "key": "$testUsername",
    "name": "$testUsername",
    "displayName": "$testDisplayName",
    "emailAddress": "$testEmail",
    "active": true
}
"@

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraUser -ModuleName JiraPS {
            $object = ConvertFrom-Json $restResultGet
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.User')
            return $object
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Put' -and $URI -eq "$jiraServer/rest/api/latest/user?username=$testUsername"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $restResultGet
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        It "Accepts a username as a String to the -User parameter" {
            { Set-JiraUser -User $testUsername -DisplayName $testDisplayNameChanged } | Should Not Throw
            Assert-MockCalled -CommandName Get-JiraUser -Exactly -Times 1 -Scope It
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Accepts a JiraPS.User object to the -User parameter" {
            $user = Get-JiraUser -UserName $testUsername
            { Set-JiraUser -User $user -DisplayName $testDisplayNameChanged } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Accepts pipeline input from Get-JiraUser" {
            { Get-JiraUser -UserName $testUsername | Set-JiraUser -DisplayName $testDisplayNameChanged } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Modifies a user's DisplayName if the -DisplayName parameter is passed" {
            # This is not a great test.
            { Set-JiraUser -User $testUsername -DisplayName $testDisplayNameChanged } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Modifies a user's EmailAddress if the -EmailAddress parameter is passed" {
            # Neither is this one.
            { Set-JiraUser -User $testUsername -EmailAddress $testEmailChanged } | Should Not Throw
            Assert-MockCalled -CommandName Invoke-JiraMethod -Exactly -Times 1 -Scope It
        }

        It "Provides no output if the -PassThru parameter is not passed" {
            $output = Set-JiraUser -User $testUsername -DisplayName $testDisplayNameChanged
            $output | Should BeNullOrEmpty
        }

        It "Outputs a JiraPS.User object if the -PassThru parameter is passed" {
            $output = Set-JiraUser -User $testUsername -DisplayName $testDisplayNameChanged -PassThru
            $output | Should Not BeNullOrEmpty
        }
    }
}
