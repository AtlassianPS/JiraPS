#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "ConvertTo-JiraVersion" -Tag 'Unit' {

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

        $versionId = '10000'
        $versionName = 'New Version 1'
        $versionDescription = 'An excellent version'
        $projectId = '20000'

        $sampleJson = @"
{
    "self": "$jiraServer/rest/api/2/version/$versionId",
    "id": "$versionId",
    "description": "$versionDescription",
    "name": "$versionName",
    "archived": false,
    "released": true,
    "releaseDate": "2010-07-06",
    "overdue": true,
    "userReleaseDate": "6/Jul/2010",
    "projectId": $projectId
}
"@

        Mock Get-JiraProject -ModuleName JiraPS {
            $Project = [PSCustomObject]@{
                Id  = $projectId
                Key = "ABC"
            }
            $Project.PSObject.TypeNames.Insert(0, 'JiraPS.Project')
            $Project
        }

        $sampleObject = ConvertFrom-Json -InputObject $sampleJson

        $r = ConvertTo-JiraVersion -InputObject $sampleObject

        It "Creates a PSObject out of JSON input" {
            $r | Should Not BeNullOrEmpty
        }

        checkPsType $r 'JiraPS.Version'

        defProp $r 'ID' $versionID
        defProp $r 'Project' $projectId
        defProp $r 'Name' $VersionName
        defProp $r 'Description' "$versionDescription"
        hasProp $r 'Archived'
        hasProp $r 'Released'
        hasProp $r 'Overdue'
        defProp $r 'RestUrl' "$jiraServer/rest/api/2/version/$versionId"
    }
}
