#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

Describe "Get-JiraComponent" -Tag 'Unit' {

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

        $projectKey = 'TEST'
        $projectId = '10004'

        $componentId = '10001'
        $componentName = 'Component 1'
        $componentId2 = '10002'
        $componentName2 = 'Component 2'

        $restResultAll = @"
[
    {
        "self": "$jiraServer/rest/api/2/component/$componentId",
        "id": "$componentId",
        "name": "$componentName",
        "project": "$projectKey",
        "projectId": "$projectId"
    },
    {
        "self": "$jiraServer/rest/api/2/component/$componentId2",
        "id": "$componentId2",
        "name": "$componentName2",
        "project": "$projectKey",
        "projectId": "$projectId"
    }
]
"@

        $restResultOne = @"
[
    {
        "self": "$jiraServer/rest/api/2/component/$componentId",
        "id": "$componentId",
        "name": "$componentName",
        "project": "$projectKey",
        "projectId": "$projectId"
    }
]
"@

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/2/component/$componentId"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $restResultOne
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
    }

    #############
    # Tests
    #############

    Context "Sanity checking" {
        It "Has expected parameters" {
            $command = Get-Command -Name Get-JiraComponent

            defParam $command 'Project'
            defParam $command 'ComponentId'
            defParam $command 'Credential'
        }
    }

    Context "Behavior testing" {
        It "Returns details about specific components if the component ID is supplied" {
            $oneResult = Get-JiraComponent -Id $componentId
            $oneResult | Should -Not -BeNullOrEmpty
            @($oneResult).Count | Should -Be 1
            $oneResult.Id | Should -Be $componentId
        }

        It "Provides the Id of the component" {
            $oneResult = Get-JiraComponent -Id $componentId
            $oneResult.Id | Should -Be $componentId
        }
    }

    Context "Internal Call Validation" {
        It "Uses Invoke-JiraMethod to get the component" {
            Get-JiraComponent -Id $componentId

            Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
        }
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH* -ErrorAction SilentlyContinue
    }
}
