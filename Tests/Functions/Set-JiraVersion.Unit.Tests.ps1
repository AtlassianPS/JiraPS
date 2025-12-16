#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7.1" }

Describe "Set-JiraVersion" -Tag 'Unit' {

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
        $versionName = '1.0.0.0'
        $versionID = '16840'
        $projectKey = 'LDD'
        $projectId = '12101'

        $JiraProjectData = @"
[
    {
        "Key" : "$projectKey",
        "Id": "$projectId"
    },
    {
        "Key" : "foo",
        "Id": "99"
    }
]
"@
        $testJsonOne = @"
{
    "self" : "$jiraServer/rest/api/2/version/$versionID",
    "id" : $versionID,
    "description" : "$versionName",
    "name" : "$versionName",
    "archived" : "False",
    "released" : "False",
    "projectId" : "12101"
}
"@

        #region Mock

        #helper functions to generate test Jira objects
        function Get-TestJiraVersion {
            $InputObject = ConvertFrom-Json $testJsonOne

            $result = New-Object -TypeName PSObject -Property @{
                Id      = $InputObject.Id
                Name    = $InputObject.name
                Project = $InputObject.projectId
                RestUrl = $InputObject.self
            }
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Version')
            $result
        }

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Get-JiraProject -ModuleName JiraPS {
            $Projects = ConvertFrom-Json $JiraProjectData
            $Projects.PSObject.TypeNames.Insert(0, 'JiraPS.Project')
            $Projects | Where-Object {$_.Key -in $Project}
        }

        Mock Get-JiraVersion -ModuleName JiraPS {
            Get-TestJiraVersion
        }

        Mock ConvertTo-JiraVersion -ModuleName JiraPS {
            $result = New-Object -TypeName PSObject -Property @{
                Id      = $InputObject.Id
                Name    = $InputObject.name
                Project = $InputObject.projectId
                RestUrl = $InputObject.self
            }
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.Version')
            $result
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/*/version/$versionID" } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $testJsonOne
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mock
    }

    Context "Sanity checking" {
        It "Has expected parameters" {
            $command = Get-Command -Name Set-JiraVersion

            defParam $command 'Version'
            defParam $command 'Name'
            defParam $command 'Description'
            defParam $command 'Archived'
            defParam $command 'Released'
            defParam $command 'ReleaseDate'
            defParam $command 'StartDate'
            defParam $command 'Project'
            defParam $command 'Credential'
        }
    }

    Context "Behavior checking" {
        It "sets an Issue's Version Name" {
            $version = Get-TestJiraVersion
            $results = Set-JiraVersion -Version $version -Name "NewName" -ErrorAction Stop
            $results | Should -Not -BeNullOrEmpty
            checkType $results "JiraPS.Version"
            Should -Invoke 'Get-JiraVersion' -Times 1 -ModuleName JiraPS -Exactly
            Should -Invoke 'Get-JiraProject' -Times 0 -ModuleName JiraPS -Exactly
            Should -Invoke 'ConvertTo-JiraVersion' -Times 1 -ModuleName JiraPS -Exactly
            Should -Invoke 'Invoke-JiraMethod' -Times 1 -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/*/version/$versionID" }
        }
        It "sets an Issue's Version Name using the pipeline" {
            $results = Get-TestJiraVersion | Set-JiraVersion -Name "NewName" -ErrorAction Stop
            $results | Should -Not -BeNullOrEmpty
            checkType $results "JiraPS.Version"
            Should -Invoke 'Get-JiraVersion' -Times 1 -ModuleName JiraPS -Exactly
            Should -Invoke 'Get-JiraProject' -Times 0 -ModuleName JiraPS -Exactly
            Should -Invoke 'ConvertTo-JiraVersion' -Times 1 -ModuleName JiraPS -Exactly
            Should -Invoke 'Invoke-JiraMethod' -Times 1 -ModuleName JiraPS -Exactly -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/*/version/$versionID" }
        }
    }

    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }
}
