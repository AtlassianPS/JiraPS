#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraLink" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:LinkID = "10000"

            $script:sampleJson = @"
{
    "id": 10000,
    "self": "http://jiraserver.example.com/rest/api/issue/MKY-1/remotelink/10000",
    "globalId": "system=http://www.mycompany.com/support&id=1",
    "application": {
        "type": "com.acme.tracker",
        "name": "My Acme Tracker"
    },
    "relationship": "causes",
    "object": {
        "url": "http://www.mycompany.com/support?id=1",
        "title": "TSTSUP-111",
        "summary": "Crazy customer support issue",
        "icon": {
            "url16x16": "http://www.mycompany.com/support/ticket.png",
            "title": "Support Ticket"
        },
        "status": {
            "resolved": true,
            "icon": {
                "url16x16": "http://www.mycompany.com/support/resolved.png",
                "title": "Case Closed",
                "link": "http://www.mycompany.com/support?id=1&details=closed"
            }
        }
    }
}
"@
            $script:sampleObject = ConvertFrom-Json -InputObject $sampleJson
            #endregion Definitions

            #region Mocks
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "Object Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraLink -InputObject $sampleObject
                }

                It "creates PSObject from JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                }

                It "adds custom type 'JiraPS.Link'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'JiraPS.Link'
                }
            }

            Context "Property Mapping" {
                BeforeAll {
                    $script:result = ConvertTo-JiraLink -InputObject $sampleObject
                }

                It "defines 'id' property with correct value" {
                    $result.id | Should -Be $LinkId
                }

                It "defines 'RestUrl' property with correct value" {
                    $result.RestUrl | Should -Be "$jiraServer/rest/api/issue/MKY-1/remotelink/10000"
                }
            }

            Context "Type Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraLink -InputObject $sampleObject
                }

                It "converts id to numeric type" {
                    $result.id | Should -BeOfType ([System.ValueType])
                    $result.id.GetType() | Should -BeIn @([int], [long], [int64])
                }
            }

            Context "Pipeline Support" {
                It "accepts pipeline input" {
                    $result = $sampleObject | ConvertTo-JiraLink
                    $result | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}
