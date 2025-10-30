#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

Describe "Add-JiraGroupMember" -Tag 'Unit' {

    BeforeAll {
        Remove-Item -Path Env:\BH* -ErrorAction SilentlyContinue
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

        Import-Module "$env:BHProjectPath/Tools/BuildTools.psm1" -ErrorAction Stop

        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Import-Module $env:BHManifestToTest -ErrorAction Stop

        # helpers used by tests (defParam / ShowMockInfo)
        . "$PSScriptRoot/../Shared.ps1"

        $jiraServer = 'http://jiraserver.example.com'

        # In most test cases, user 1 is a member of the group and user 2 is not
        $testGroupName = 'testGroup'
        $testUsername1 = 'testUsername1'
        $testUsername2 = 'testUsername2'


        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        # Helper functions for test objects
        function New-TestJiraGroup {
            param($Name = $testGroupName)
            $object = [PSCustomObject] @{
                'Name' = $Name
                'Size' = 2
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Group')
            return $object
        }

        Mock Get-JiraGroup -ModuleName JiraPS {
            New-TestJiraGroup
        }

        Mock Get-JiraUser -ModuleName JiraPS {
            foreach ($user in $UserName) {
                $object = [PSCustomObject] @{
                    'Name' = "$user"
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.User')
                Write-Output $object
            }
        }

        Mock Get-JiraGroupMember -ModuleName JiraPS {
            @(
                [PSCustomObject] @{
                    'Name' = $testUsername1
                }
            )
        }

        Mock ConvertTo-JiraGroup -ModuleName JiraPS {
            $InputObject
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
            return $true
        }
    }

    #############
    # Tests
    #############
    Context "Sanity checking" {

        It "Accepts a group name as a String to the -Group parameter" {
            { Add-JiraGroupMember -Group $testGroupName -User $testUsername2 } | Should -Not -Throw
            { Add-JiraGroupMember -Group $testGroupName -User $testUsername2 -PassThru } | Should -Not -Throw
            Should -Invoke -CommandName Get-JiraGroup -ModuleName JiraPS -Times 2 -Exactly
            Should -Invoke -CommandName Get-JiraGroupMember -ModuleName JiraPS -Times 2 -Exactly
            Should -Invoke -CommandName Get-JiraUser -ModuleName JiraPS -Times 2 -Exactly
            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$URI -match $testGroupName} -Times 2 -Exactly
            Should -Invoke -CommandName ConvertTo-JiraGroup -ModuleName JiraPS -Times 1 -Exactly
        }

        It "Accepts a JiraPS.Group object to the -Group parameter" {
            $group = New-TestJiraGroup
            { Add-JiraGroupMember -Group $group -User $testUsername2 } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$URI -match $testGroupName} -Times 1 -Exactly
        }

        It "Accepts pipeline input from Get-JiraGroup" {
            { New-TestJiraGroup | Add-JiraGroupMember -User $testUsername2 } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$URI -match $testGroupName} -Times 1 -Exactly
        }
    }

    Context "Behavior testing" {

        It "Tests to see if a provided user is currently a member of the provided JIRA group before attempting to add them" {
            { Add-JiraGroupMember -Group $testGroupName -User $testUsername1 -ErrorAction Stop } | Should -Throw
            Should -Invoke -CommandName Get-JiraGroupMember -ModuleName JiraPS -Times 1 -Exactly
        }

        It "Adds a user to a JIRA group if the user is not a member" {
            { Add-JiraGroupMember -Group $testGroupName -User $testUsername2 } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'POST' -and $URI -match $testGroupName -and $Body -match $testUsername2} -Times 1 -Exactly
        }

        It "Adds multiple users to a JIRA group if they are passed to the -User parameter" {

            # Override our previous mock so we have no group members
            Mock Get-JiraGroupMember -ModuleName JiraPS { @() }

            # Should use the REST method twice, since at present, you can only add one group member per API call
            { Add-JiraGroupMember -Group $testGroupName -User $testUsername1, $testUsername2 } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Post' -and $URI -match $testGroupName} -Times 2 -Exactly
        }
    }

    Context "Error checking" {
        It "Gracefully handles cases where a provided user is already in the provided group" {
            { Add-JiraGroupMember -Group $testGroupName -User $testUsername1, $testUsername2 -ErrorAction SilentlyContinue } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Post' -and $URI -match $testGroupName} -Times 1 -Exactly
        }
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH* -ErrorAction SilentlyContinue
    }
}
