#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "Move-JiraVersion" -Tag 'Unit' {

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

        $versionID1 = 16840
        $versionID2 = 16940
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

        #region Mock

        Mock Get-JiraProject -ModuleName JiraPS {
            $Projects = ConvertFrom-Json $JiraProjectData
            $Projects.PSObject.TypeNames.Insert(0, 'JiraPS.Project')
            $Projects | Where-Object {$_.Key -in $Project}
        }

        Mock Get-JiraVersion -ModuleName JiraPS {
            foreach ($_id in $Id) {
                $Version = [PSCustomObject]@{
                    Id          = $_Id
                    Name        = "v1"
                    Description = "My Desccription"
                    Project     = (Get-JiraProject -Project $projectKey)
                    ReleaseDate = (Get-Date "2017-12-01")
                    StartDate   = (Get-Date "2017-01-01")
                    RestUrl     = "rest/api/latest/version/$_Id"
                }
                $Version.PSObject.TypeNames.Insert(0, 'JiraPS.Version')
                $Version
            }
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'POST' -and $URI -like "rest/api/*/version/$versionID1/move" } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'POST' -and $URI -like "rest/api/*/version/$versionID2/move" } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mock

        Context "Sanity checking" {
            $command = Get-Command -Name Move-JiraVersion

            defParam $command 'Version'
            defParam $command 'Position'
            defParam $command 'After'
            defParam $command 'Session'
        }

        Context "ByPosition behavior checking" {
            It 'moves a Version using its ID and Last Position' {
                { Move-JiraVersion -Version $versionID1 -Position Last -ErrorAction Stop } | Should Not Throw
                Assert-MockCalled 'Get-JiraVersion' -Times 0 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter {
                    $Method -eq 'POST' -and
                    $URI -like "rest/api/latest/version/$versionID1/move" -and
                    $Body -match '"position":\s*"Last"'
                }
            }
            It 'moves a Version using its ID and Earlier Position' {
                { Move-JiraVersion -Version $versionID1 -Position Earlier -ErrorAction Stop } | Should Not Throw
                Assert-MockCalled 'Get-JiraVersion' -Times 0 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter {
                    $Method -eq 'POST' -and
                    $URI -like "rest/api/latest/version/$versionID1/move" -and
                    $Body -match '"position":\s*"Earlier"'
                }
            }
            It 'moves a Version using a JiraPS.Version object and Later Position' {
                {
                    $version = Get-JiraVersion -ID $versionID2
                    Move-JiraVersion -Version $version -Position Later -ErrorAction Stop
                } | Should Not Throw
                Assert-MockCalled 'Get-JiraVersion' -Times 1 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter {
                    $Method -eq 'POST' -and
                    $URI -like "rest/api/latest/version/$versionID2/move" -and
                    $Body -match '"position":\s*"Later"'
                }
            }
            It 'moves a Version using JiraPS.Version object and First Position' {
                {
                    $version = Get-JiraVersion -ID $versionID2
                    Move-JiraVersion -Version $version -Position First -ErrorAction Stop
                } | Should Not Throw
                Assert-MockCalled 'Get-JiraVersion' -Times 1 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter {
                    $Method -eq 'POST' -and
                    $URI -like "rest/api/latest/version/$versionID2/move" -and
                    $Body -match '"position":\s*"First"'
                }
            }
            It 'moves a Version using JiraPS.Version object over pipeline and First Position' {
                {
                    $version = Get-JiraVersion -ID $versionID2
                    $version | Move-JiraVersion -Position First -ErrorAction Stop
                } | Should Not Throw
                Assert-MockCalled 'Get-JiraVersion' -Times 1 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter {
                    $Method -eq 'POST' -and
                    $URI -like "rest/api/latest/version/$versionID2/move" -and
                    $Body -match '"position":\s*"First"'
                }
            }
            It 'moves a Version using its ID over pipeline and First Position' {
                {
                    $versionID1 | Move-JiraVersion -Position First -ErrorAction Stop
                } | Should Not Throw
                Assert-MockCalled 'Get-JiraVersion' -Times 0 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter {
                    $Method -eq 'POST' -and
                    $URI -like "rest/api/latest/version/$versionID1/move" -and
                    $Body -match '"position":\s*"First"'
                }
            }
        }
        Context "ByAfter behavior checking" {
            It 'moves a Version using its ID and other Version ID' {
                $restUrl = (Get-JiraVersion -Id $versionID2).RestUrl
                { Move-JiraVersion -Version $versionID1 -After $versionID2 -ErrorAction Stop } | Should Not Throw
                Assert-MockCalled 'Get-JiraVersion' -Times 2 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter {
                    $Method -eq 'POST' -and
                    $URI -like "rest/api/latest/version/$versionID1/move" -and
                    $Body -match """after"":\s*""$restUrl"""
                }
            }
            It 'moves a Version using JiraPS.Version object and other Version ID' {
                $restUrl = (Get-JiraVersion -Id $versionID2).RestUrl
                $version1 = Get-JiraVersion -ID $versionID1
                { Move-JiraVersion -Version $version1 -After $versionID2 -ErrorAction Stop } | Should Not Throw
                Assert-MockCalled 'Get-JiraVersion' -Times 3 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter {
                    $Method -eq 'POST' -and
                    $URI -like "rest/api/latest/version/$versionID1/move" -and
                    $Body -match """after"":\s*""$restUrl"""
                }
            }
            It 'moves a Version using its ID and other Version JiraPS.Version object' {
                $version2 = Get-JiraVersion -ID $versionID2
                { Move-JiraVersion -Version $versionID1 -After $version2 -ErrorAction Stop } | Should Not Throw
                Assert-MockCalled 'Get-JiraVersion' -Times 1 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter {
                    $Method -eq 'POST' -and
                    $URI -like "rest/api/latest/version/$versionID1/move" -and
                    $Body -match """after"":\s*""$($version2.RestUrl)"""
                }
            }
            It 'moves a Version using its ID over pipeline and other Version JiraPS.Version object' {
                $version2 = Get-JiraVersion -ID $versionID2
                { $versionID1 | Move-JiraVersion -After $version2 -ErrorAction Stop } | Should Not Throw
                Assert-MockCalled 'Get-JiraVersion' -Times 1 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter {
                    $Method -eq 'POST' -and
                    $URI -like "rest/api/latest/version/$versionID1/move" -and
                    $Body -match """after"":\s*""$($version2.RestUrl)"""
                }
            }
            It 'moves a Version using JiraPS.Version object over pipeline and other Version JiraPS.Version object' {
                $version1 = Get-JiraVersion -ID $versionID1
                $version2 = Get-JiraVersion -ID $versionID2
                { $version1 | Move-JiraVersion -After $version2 -ErrorAction Stop } | Should Not Throw
                Assert-MockCalled 'Get-JiraVersion' -Times 2 -Scope It -ModuleName JiraPS -Exactly
                Assert-MockCalled 'Invoke-JiraMethod' -Times 1 -Scope It -ModuleName JiraPS -Exactly -ParameterFilter {
                    $Method -eq 'POST' -and
                    $URI -like "rest/api/latest/version/$versionID1/move" -and
                    $Body -match """after"":\s*""$($version2.RestUrl)"""
                }
            }
        }
    }
}
