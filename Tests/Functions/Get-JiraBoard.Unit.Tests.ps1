#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "Get-JiraBoard" -Tag 'Unit' {

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

        $boardType = 'scrum'
        $boardId = '10003'
        $boardName = 'IT'

        $boardType2 = 'kanban'
        $boardId2 = '10004'
        $boardName2 = 'TestBoard'

        $restResultAll = @"
[
    {
        "self": "$jiraServer/rest/agile/1.0/board/$boardId",
        "id": "$boardId",
        "type": "$boardType",
        "name": "$boardName"
    },
    {
        "self": "$jiraServer/rest/agile/1.0/board/$boardId2",
        "id": "$boardId2",
        "type": "$boardType2",
        "name": "$boardName2"
    }
]
"@

        $restResultOne = @"
[
    {
        "self": "$jiraServer/rest/agile/1.0/board/$boardId",
        "id": "$boardId",
        "type": "$boardType",
        "name": "$boardName"
    }
]
"@

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -like "$jiraServer/rest/agile/*/board/"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $restResultAll
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'GET' -and $URI -like "$jiraServer/rest/agile/*/board/" -and $GetParameter["name"] -eq $boardName} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $restResultOne
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        It "Returns all boards if called with no parameters" {
            $allResults = Get-JiraBoard
            $allResults | Should Not BeNullOrEmpty
            @($allResults).Count | Should Be (ConvertFrom-Json -InputObject $restResultAll).Count
        }

        It "Returns details about specific boards if the board key is supplied" {
            $oneResult = Get-JiraBoard -Board $boardName
            $oneResult | Should Not BeNullOrEmpty
            @($oneResult).Count | Should Be 1
        }

        It "Provides the ID of the board" {
            $oneResult = Get-JiraBoard -Board $boardName
            $oneResult.Id | Should Be $boardId
        }
    }
}
