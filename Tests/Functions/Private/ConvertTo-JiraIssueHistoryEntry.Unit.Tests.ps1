#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraIssueHistoryEntry" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:sampleJson = @"
{
    "id": "10001",
    "author": {
        "name": "jdoe"
    },
    "created": "2020-01-01T12:00:00.000+0000",
    "items": [
        {
            "field": "status",
            "fromString": "To Do",
            "toString": "In Progress"
        }
    ]
}
"@

            $script:sampleObject = ConvertFrom-Json -InputObject $sampleJson
            #endregion Definitions

            #region Mocks
            Mock ConvertTo-JiraUser -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraUser'

                [PSCustomObject]@{
                    PSTypeName = 'AtlassianPS.JiraPS.User'
                    Name       = $InputObject.name
                }
            }
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "Object conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraIssueHistoryEntry -InputObject $sampleObject
                }

                It "creates an output object" {
                    $result | Should -Not -BeNullOrEmpty
                }

                It "adds custom type JiraPS.IssueHistoryEntry" {
                    $result.PSObject.TypeNames[0] | Should -Be 'JiraPS.IssueHistoryEntry'
                }
            }

            Context "Property mapping" {
                BeforeAll {
                    $script:result = ConvertTo-JiraIssueHistoryEntry -InputObject $sampleObject
                }

                It "maps Id" {
                    $result.Id | Should -Be '10001'
                }

                It "maps Created as DateTime" {
                    $result.Created | Should -BeOfType ([DateTime])
                }

                It "maps Items collection" {
                    @($result.Items) | Should -HaveCount 1
                    $result.Items[0].field | Should -Be 'status'
                }

                It "converts Author using ConvertTo-JiraUser" {
                    $null = ConvertTo-JiraIssueHistoryEntry -InputObject $sampleObject

                    $result.Author.Name | Should -Be 'jdoe'
                    Should -Invoke ConvertTo-JiraUser -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }
            }

            Context "Pipeline support" {
                It "accepts pipeline input" {
                    $result = $sampleObject | ConvertTo-JiraIssueHistoryEntry

                    $result | Should -Not -BeNullOrEmpty
                    $result.Id | Should -Be '10001'
                }
            }
        }
    }
}
