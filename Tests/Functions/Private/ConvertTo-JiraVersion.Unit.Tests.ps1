#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
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

        }

        Describe "Behavior" {
            It 'maps the version response into a typed model with correct values' {
                $result = ConvertTo-JiraVersion -InputObject $sampleObject

                $result | Should -BeOfType ([AtlassianPS.JiraPS.Version])
                $result.Id | Should -Be $versionId
                $result.Project | Should -BeOfType [long]
                $result.Project | Should -Be $projectId
                $result.Name | Should -Be $versionName
                $result.Description | Should -Be $versionDescription
                $result.Archived | Should -BeFalse
                $result.Released | Should -BeTrue
                $result.Overdue | Should -BeTrue
                $result.RestUrl.AbsoluteUri | Should -Be "$jiraServer/rest/api/2/version/$versionId"
            }

            Context "Type Conversion" {
                It "leaves Project null when projectId is missing from the payload" {
                    $payloadWithoutProject = $sampleObject.PSObject.Copy()
                    $payloadWithoutProject.PSObject.Properties.Remove('projectId')

                    $defaulted = ConvertTo-JiraVersion -InputObject $payloadWithoutProject

                    $defaulted.Project | Should -BeNullOrEmpty
                }
            }

            Context "Pipeline Support" {
                It 'preserves distinct versions and their order through the pipeline' {
                    $otherVersion = $sampleObject.PSObject.Copy()
                    $otherVersion.id = '10001'
                    $otherVersion.name = 'Next version'
                    $result = @($sampleObject, $otherVersion | ConvertTo-JiraVersion)

                    $result | Should -HaveCount 2
                    $result.Id | Should -Be @('10000', '10001')
                    $result.Name | Should -Be @($versionName, 'Next version')
                }
            }
        }
    }
}
