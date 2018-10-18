#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "Get-JiraField" -Tag 'Unit' {

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

        # In my Jira instance, this returns 34 objects. I've stripped it down quite a bit for testing.
        $restResult = @"
[
    {
        "id": "issuetype",
        "name": "Issue Type",
        "custom": false,
        "orderable": true,
        "navigable": true,
        "searchable": true,
        "clauseNames": [
            "issuetype",
            "type"
        ],
        "schema": {
            "type": "issuetype",
            "system": "issuetype"
        }
    },
    {
        "id": "project",
        "name": "Project",
        "custom": false,
        "orderable": false,
        "navigable": true,
        "searchable": true,
        "clauseNames": [
            "project"
        ],
        "schema": {
            "type": "project",
            "system": "project"
        }
    },
    {
        "id": "status",
        "name": "Status",
        "custom": false,
        "orderable": false,
        "navigable": true,
        "searchable": true,
        "clauseNames": [
            "status"
        ],
        "schema": {
            "type": "status",
            "system": "status"
        }
    },
    {
        "id": "issuekey",
        "name": "Key",
        "custom": false,
        "orderable": false,
        "navigable": true,
        "searchable": false,
        "clauseNames": [
            "id",
            "issue",
            "issuekey",
            "key"
        ]
    },
    {
        "id": "description",
        "name": "Description",
        "custom": false,
        "orderable": true,
        "navigable": true,
        "searchable": true,
        "clauseNames": [
            "description"
        ],
        "schema": {
            "type": "string",
            "system": "description"
        }
    },
    {
        "id": "summary",
        "name": "Summary",
        "custom": false,
        "orderable": true,
        "navigable": true,
        "searchable": true,
        "clauseNames": [
            "summary"
        ],
        "schema": {
            "type": "string",
            "system": "summary"
        }
    },
    {
        "id": "reporter",
        "name": "Reporter",
        "custom": false,
        "orderable": true,
        "navigable": true,
        "searchable": true,
        "clauseNames": [
            "reporter"
        ],
        "schema": {
            "type": "user",
            "system": "reporter"
        }
    },
    {
        "id": "comment",
        "name": "Comment",
        "custom": false,
        "orderable": true,
        "navigable": false,
        "searchable": true,
        "clauseNames": [
            "comment"
        ],
        "schema": {
            "type": "array",
            "items": "comment",
            "system": "comment"
        }
    }
]
"@

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $Uri -eq "$jiraServer/rest/api/latest/field"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $restResult
        }

        Mock ConvertTo-JiraField {
            $InputObject
        }

        It "Gets all fields in Jira if called with no parameters" {
            $allResults = Get-JiraField
            $allResults | Should Not BeNullOrEmpty
            @($allResults).Count | Should Be @((ConvertFrom-Json -InputObject $restResult)).Count
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
        }

        It "Gets a specified field if a field ID is provided" {
            $oneResult = Get-JiraField -Field issuetype
            $oneResult | Should Not BeNullOrEmpty
            $oneResult.ID | Should Be 'issuetype'
            $oneResult.Name | Should Be 'Issue Type'
        }

        It "Gets a specified issue type if an issue type name is provided" {
            $oneResult = Get-JiraField -Field 'Issue Type'
            $oneResult | Should Not BeNullOrEmpty
            $oneResult.ID | Should Be 'issuetype'
            $oneResult.Name | Should Be 'Issue Type'
        }

        It "Handles positional parameters correctly" {
            $oneResult = Get-JiraField 'Issue Type'
            $oneResult | Should Not BeNullOrEmpty
            $oneResult.ID | Should Be issuetype
            $oneResult.Name | Should Be 'Issue Type'
        }

        It "Uses ConvertTo-JiraField to beautify output" {
            Assert-MockCalled 'ConvertTo-JiraField'
        }
    }
}
