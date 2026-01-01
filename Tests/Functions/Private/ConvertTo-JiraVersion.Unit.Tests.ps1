#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraVersion" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:versionId = '10000'
            $script:versionName = 'New Version 1'
            $script:versionDescription = 'An excellent version'
            $script:projectId = '20000'

            $script:sampleJson = @"
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
            $script:sampleObject = ConvertFrom-Json -InputObject $sampleJson
            #endregion Definitions

            #region Mocks
            Mock Get-JiraProject -ModuleName JiraPS {
                $Project = [PSCustomObject]@{
                    Id  = $projectId
                    Key = "ABC"
                }
                $Project.PSObject.TypeNames.Insert(0, 'JiraPS.Project')
                $Project
            }
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "Object Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraVersion -InputObject $sampleObject
                }

                It "creates PSObject from JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                }

                It "adds custom type 'JiraPS.Version'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'JiraPS.Version'
                }
            }

            Context "Property Mapping" {
                BeforeAll {
                    $script:result = ConvertTo-JiraVersion -InputObject $sampleObject
                }

                It "defines 'ID' property with correct value" {
                    $result.ID | Should -Be $versionID
                }

                It "defines 'Project' property with correct value" {
                    $result.Project | Should -Be $projectId
                }

                It "defines 'Name' property with correct value" {
                    $result.Name | Should -Be $VersionName
                }

                It "defines 'Description' property with correct value" {
                    $result.Description | Should -Be "$versionDescription"
                }

                It "defines 'Archived' property" {
                    $result.Archived | Should -Not -BeNullOrEmpty
                }

                It "defines 'Released' property" {
                    $result.Released | Should -Not -BeNullOrEmpty
                }

                It "defines 'Overdue' property" {
                    $result.Overdue | Should -Not -BeNullOrEmpty
                }

                It "defines 'RestUrl' property with correct value" {
                    $result.RestUrl | Should -Be "$jiraServer/rest/api/2/version/$versionId"
                }
            }

            Context "Type Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraVersion -InputObject $sampleObject
                }

                It "converts Archived to correct type" {
                    $result.Archived | Should -BeOfType [bool]
                }

                It "converts Released to correct type" {
                    $result.Released | Should -BeOfType [bool]
                }

                It "converts Overdue to correct type" {
                    $result.Overdue | Should -BeOfType [bool]
                }
            }

            Context "Pipeline Support" {
                It "accepts pipeline input" {
                    $result = $sampleObject | ConvertTo-JiraVersion
                    $result | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}
