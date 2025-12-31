#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

Describe 'Get-JiraIssueLinkType' -Tag 'Unit' {

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

        . "$PSScriptRoot/../Shared.ps1"

        $jiraServer = 'http://jiraserver.example.com'
        $testLinkName = 'myLink'


        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        $filterAll = {$Method -eq 'Get' -and $Uri -ceq "$jiraServer/rest/api/2/issueLinkType"}
        $filterOne = {$Method -eq 'Get' -and $Uri -ceq "$jiraServer/rest/api/2/issueLinkType/10000"}

        Mock ConvertTo-JiraIssueLinkType -ModuleName JiraPS {
            ShowMockInfo 'ConvertTo-JiraIssueLinkType'

            # We also don't care what comes out of here - this function has its own tests
            [PSCustomObject] @{
                PSTypeName = 'JiraPS.IssueLinkType'
                foo        = 'bar'
            }
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter $filterAll {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            [PSCustomObject] @{
                issueLinkTypes = @(
                    'foo'
                    $testLinkName
                )
            }
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter $filterOne {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            [PSCustomObject] @{
                issueLinkTypes = @(
                    'bar'
                )
            }
        }
    }

    Context "Sanity checking" {
        It "Has the expected parameters" {
            $command = Get-Command -Name Get-JiraIssueLinkType

            defParam $command 'LinkType'
            defParam $command 'Credential'
        }
    }

    Context "Behavior testing - returning all link types" {
        BeforeAll {
            $output = Get-JiraIssueLinkType
        }

        It 'Uses Invoke-JiraMethod to communicate with JIRA' {
            Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter $filterAll -Exactly 1 -Scope Context
        }

        It 'Returns all link types if no value is passed to the -LinkType parameter' {
            $output | Should -Not -BeNullOrEmpty
        }

        It 'Uses the helper method ConvertTo-JiraIssueLinkType to process output' {
            Should -Invoke 'ConvertTo-JiraIssueLinkType' -ModuleName JiraPS -ParameterFilter {$InputObject -contains 'foo'} -Exactly 1 -Scope Context
        }
    }

    Context "Behavior testing - returning one link type" {
        It 'Returns a single link type if an ID number is passed to the -LinkType parameter' {
            $output = Get-JiraIssueLinkType -LinkType 10000
            Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter $filterOne -Exactly 1
            $output | Should -Not -BeNullOrEmpty
            @($output).Count | Should -Be 1
        }

        It 'Returns the correct link type if a type name is passed to the -LinkType parameter' {
            Mock ConvertTo-JiraIssueLinkType -ModuleName JiraPS {
                ShowMockInfo 'ConvertTo-JiraIssueLinkType'

                [PSCustomObject] @{
                    PSTypeName = 'JiraPS.IssueLinkType'
                    Name       = 'myLink'
                    ID         = 5
                }
            }

            $output = Get-JiraIssueLinkType -LinkType $testLinkName
            Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter $filterAll -Exactly 1
            $output | Should -Not -BeNullOrEmpty
            @($output).Count | Should -Be 1
            $output.ID | Should -Be 5
        }
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }
}
