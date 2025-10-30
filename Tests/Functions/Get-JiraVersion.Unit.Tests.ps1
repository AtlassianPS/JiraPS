#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

Describe "Get-JiraVersion" -Tag 'Unit' {

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

        #region Definitions
        $jiraServer = 'http://jiraserver.example.com'
        $versionName1 = 'v1.0'
        $versionName2 = 'v2.0'
        $versionName3 = 'v3.0'
        $versionID1 = 16740
        $versionID2 = 16840
        $versionID3 = 16940
        $projectKey = 'LDD'
        $projectId = '12101'

        $JiraProjectData = @"
[
    {
        "Key" : "$projectKey",
        "id": "$projectId"
    },
    {
        "Key" : "foo",
        "id": "0"
    }
]
"@
        $testJson1 = @"
{
    "self" : "$jiraServer/rest/api/2/version/$versionID1",
    "id" : $versionID1,
    "description" : "$versionName1",
    "name" : "$versionName1",
    "archived" : "False",
    "released" : "False",
    "projectId" : "$projectId"
}
"@
        $testJson2 = @"
{
    "self" : "$jiraServer/rest/api/2/version/$versionID2",
    "id" : $versionID2,
    "description" : "$versionName2",
    "name" : "$versionName2",
    "archived" : "False",
    "released" : "False",
    "projectId" : "$projectId"
}
"@
        $testJsonAll = @"
[
    {
        "self" : "$jiraServer/rest/api/2/version/$versionID1",
        "id" : $versionID1,
        "description" : "$versionName1",
        "name" : "$versionName1",
        "archived" : "False",
        "released" : "False",
        "projectId" : "$projectId"
    },
    {
        "self" : "$jiraServer/rest/api/2/version/$versionID2",
        "id" : $versionID2,
        "description" : "$versionName2",
        "name" : "$versionName2",
        "archived" : "False",
        "released" : "False",
        "projectId" : "$projectId"
    },
    {
        "self" : "$jiraServer/rest/api/2/version/$versionID3",
        "id" : $versionID3,
        "description" : "$versionName3",
        "name" : "$versionName3",
        "archived" : "False",
        "released" : "False",
        "projectId" : "$projectId"
    }
]
"@
        #endregion Definitions

        # Helper function to create test JiraProject object
        function Get-TestJiraProject {
            param($Project)
            $json = ConvertFrom-Json $JiraProjectData
            $object = $json | Where-Object {$_.Key -in $Project}
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Project')
            return $object
        }

        # Helper function to create test JiraVersion object
        function Get-TestJiraVersion {
            param($Version)

            $result = New-Object -TypeName PSObject -Property @{
                Id      = $Version.Id
                Name    = $Version.Name
                Project = $Version.projectId
            }
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Version')
            $result
        }

        #region Mocks
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraProject -ModuleName JiraPS {
            Get-TestJiraProject -Project $Project
        }

        Mock ConvertTo-JiraVersion -ModuleName JiraPS {
            Get-TestJiraVersion $InputObject
            <# $result = New-Object -TypeName PSObject -Property @{
                Id      = $InputObject.Id
                Name    = $InputObject.name
                Project = $InputObject.projectId
            }
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Version')
            $result #>
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/2/version/$versionId1" } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $testJson1
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/version/$versionId2" } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $testJson2
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/version" } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $testJsonAll
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/project/*/version" } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $testJsonAll
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mocks
    }

    Context "Sanity checking" {
        It "Has expected parameters" {
            $command = Get-Command -Name Get-JiraVersion

            defParam $command 'Project'
            defParam $command 'Name'
            defParam $command 'ID'
            defParam $command 'Credential'
        }
    }

    Context "Behavior checking" {
        It "gets a Version using Id Parameter Set" {
            $results = Get-JiraVersion -Id $versionID1

            $results | Should -Not -BeNullOrEmpty

            Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -like "*/rest/api/*/version/$versionID1"
            } -Exactly 1

            Should -Invoke 'ConvertTo-JiraVersion' -ModuleName JiraPS -Exactly 1
        }

        It "gets a Version using multiple IDs" {
            $results = Get-JiraVersion -Id $versionID1, $versionID2

            $results | Should -Not -BeNullOrEmpty

            Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -like "*/rest/api/*/version/$versionID1"
            } -Exactly 1

            Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -like "*/rest/api/*/version/$versionID2"
            } -Exactly 1

            Should -Invoke 'ConvertTo-JiraVersion' -ModuleName JiraPS -Exactly 2
        }

        It "gets a Version using the pipeline from another Version" {
            $version1 = Get-TestJiraVersion ([PSCustomObject]@{
                Id = [int]($versionID2)
                Name = $versionName1
                ProjectId = $projectId
            })
            $version2 = Get-TestJiraVersion ([PSCustomObject]@{
                Id = [int]($versionID2)
                Name = $versionName2
                ProjectId = $projectId
            })

            $results1 = ($version1 | Get-JiraVersion)
            $results2 = ($version2 | Get-JiraVersion)
            $results1 | Should -Not -BeNullOrEmpty
            $results2 | Should -Not -BeNullOrEmpty

            Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -like "*/rest/api/*/version/$versionID2"
            } -Exactly 2

            Should -Invoke 'ConvertTo-JiraVersion' -ModuleName JiraPS -Exactly 2
        }

        It "gets all Versions using Project Parameter Set" {
            $results = Get-JiraVersion -Project $projectKey

            $results | Should -Not -BeNullOrEmpty

            Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -like "*/rest/api/*/project/$projectKey/version" -and
                $Paging -eq $true
            } -Exactly 1

            Should -Invoke 'Get-JiraProject' -ModuleName JiraPS -Exactly 1

            Should -Invoke 'ConvertTo-JiraVersion' -ModuleName JiraPS -Exactly 0
        }

        It "gets all Versions using Project as pipe input" {
            $results = Get-TestJiraProject -Project $projectKey | Get-JiraVersion

            $results | Should -Not -BeNullOrEmpty

            Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -like "*/rest/api/*/project/$projectKey/version" -and
                $Paging -eq $true
            } -Exactly 1

            # Get-JiraProject is called once in the It block
            # and once in the `Get-JiraVersion`
            Should -Invoke 'Get-JiraProject' -ModuleName JiraPS -Exactly 1

            Should -Invoke 'ConvertTo-JiraVersion' -ModuleName JiraPS -Exactly 0
        }

        It "gets all Versions from multiple Projects" {
            $results = Get-JiraVersion -Project $projectKey, "foo"

            $results | Should -Not -BeNullOrEmpty

            Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -like "*/rest/api/*/project/*/version" -and
                $Paging -eq $true
            } -Exactly 2

            Should -Invoke 'Get-JiraProject' -ModuleName JiraPS -Exactly 2

            Should -Invoke 'ConvertTo-JiraVersion' -ModuleName JiraPS -Exactly 0
        }

        It "filters the Versions from a Project by Name" {
            $results = Get-JiraVersion -Project $projectKey -Name $versionName1

            $results | Should -Not -BeNullOrEmpty

            Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -like "*/rest/api/*/project/*/version" -and
                $Paging -eq $true
            } -Exactly 1

            Should -Invoke 'Get-JiraProject' -ModuleName JiraPS -Exactly 1

            Should -Invoke 'ConvertTo-JiraVersion' -ModuleName JiraPS -Exactly 0
        }

        It "filters the Versions from a Project by multiple Names" {
            $results = Get-JiraVersion -Project $projectKey -Name $versionName1, $versionName2

            $results | Should -Not -BeNullOrEmpty

            Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -like "*/rest/api/*/project/*/version" -and
                $Paging -eq $true
            } -Exactly 1

            Should -Invoke 'Get-JiraProject' -ModuleName JiraPS -Exactly 1

            Should -Invoke 'ConvertTo-JiraVersion' -ModuleName JiraPS -Exactly 0
        }

        It "Supports the -Skip parameters to page through search results" {
            { Get-JiraVersion -Project $projectKey -Skip 10 } | Should -Not -Throw

            Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -like '*/rest/api/*/project/*/version' -and
                $Paging -eq $true -and
                $Skip -eq 10
            } -Exactly 1
        }

        It "Supports the -First parameters to page through search results" {
            { Get-JiraVersion -Project $projectKey -First 50 } | Should -Not -Throw

            Should -Invoke 'Invoke-JiraMethod' -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -like '*/rest/api/*/project/*/version' -and
                $Paging -eq $true -and
                $First -eq 50
            } -Exactly 1
        }

        It "assert VerifiableMock" {
            Assert-VerifiableMock
        }
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }
}
