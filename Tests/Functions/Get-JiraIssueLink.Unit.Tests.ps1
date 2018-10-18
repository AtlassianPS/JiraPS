#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "Get-JiraIssueLink" -Tag 'Unit' {

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

        $issueLinkId = 1234

        # We don't care about anything except for the id
        $resultsJson = @"
{
    "id": "$issueLinkId",
    "self": "",
    "type": {},
    "inwardIssue": {},
    "outwardIssue": {}
}
"@

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/2/issueLink/1234"} {
            ConvertFrom-Json $resultsJson
        }

        Mock Get-JiraIssue -ModuleName JiraPS -ParameterFilter {$Key -eq "TEST-01"} {
            # We don't care about the content of any field except for the id
            $obj = [PSCustomObject]@{
                "id"          = $issueLinkId
                "type"        = "foo"
                "inwardIssue" = "bar"
            }
            $obj.PSObject.TypeNames.Insert(0, 'JiraPS.IssueLink')
            return [PSCustomObject]@{
                issueLinks = @(
                    $obj
                )
            }
        }

        #############
        # Tests
        #############

        It "Returns details about specific issuelink" {
            $result = Get-JiraIssueLink -Id $issueLinkId
            $result | Should Not BeNullOrEmpty
            @($result).Count | Should Be 1
        }

        It "Provides the key of the project" {
            $result = Get-JiraIssueLink -Id $issueLinkId
            $result.Id | Should Be $issueLinkId
        }

        It "Accepts input from pipeline" {
            $result = (Get-JiraIssue -Key TEST-01).issuelinks | Get-JiraIssueLink
            $result.Id | Should Be $issueLinkId
        }

        It 'Fails if input from the pipeline is of the wrong type' {
            { [PSCustomObject]@{id = $issueLinkId} | Get-JiraIssueLink } | Should Throw
        }
    }
}
