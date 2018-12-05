#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "Get-JiraGroup" -Tag 'Unit' {

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

        $testGroupName = 'Test Group'
        $testGroupNameEscaped = ConvertTo-URLEncoded $testGroupName
        $testGroupSize = 1

        $restResult = @"
{
    "name": "$testGroupName",
    "self": "$jiraServer/rest/api/2/group?groupname=$testGroupName",
    "users": {
        "size": "$testGroupSize",
        "items": [],
        "max-results": 50,
        "start-index": 0,
        "end-index": 0
    },
    "expand": "users"
}
"@

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        # Searching for a group.
        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/latest/group?groupname=$testGroupNameEscaped"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json -InputObject $restResult
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        Mock ConvertTo-JiraGroup { $InputObject }

        #############
        # Tests
        #############

        It "Gets information about a provided Jira group" {
            $getResult = Get-JiraGroup -GroupName $testGroupName
            $getResult | Should Not BeNullOrEmpty
        }

        It "Uses ConvertTo-JiraGroup to beautify output" {
            Assert-MockCalled 'ConvertTo-JiraGroup'
        }
    }
}
