#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraServerInfo" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'

            $script:sampleJson = @"
{
    "baseUrl":"$jiraServer",
    "version":"1000.1323.0",
    "versionNumbers":[1000,1323,0],
    "deploymentType":"Cloud",
    "buildNumber":100062,
    "buildDate":"2017-09-26T00:00:00.000+0200",
    "serverTime":"2017-09-27T09:59:25.520+0200",
    "scmInfo":"f3c60100df073e3576f9741fb7a3dc759b416fde",
    "serverTitle":"JIRA"
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
                    $script:result = ConvertTo-JiraServerInfo -InputObject $sampleObject
                }

                It "creates PSObject from JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                }

                It "adds custom type 'AtlassianPS.JiraPS.ServerInfo'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.ServerInfo'
                }
            }

            Context "Property Mapping" {
                BeforeAll {
                    $script:result = ConvertTo-JiraServerInfo -InputObject $sampleObject
                }

                It "defines 'BaseURL' property with correct value" {
                    $result.BaseURL | Should -Be $jiraServer
                }

                It "defines 'Version' property with correct value" {
                    $result.Version | Should -Be ([Version]"1000.1323.0")
                }

                It "defines 'DeploymentType' property with correct value" {
                    $result.DeploymentType | Should -Be "Cloud"
                }

                It "defines 'BuildNumber' property with correct value" {
                    $result.BuildNumber | Should -Be 100062
                }

                It "defines 'BuildDate' property with correct value" {
                    $result.BuildDate | Should -Be (Get-Date '2017-09-26T00:00:00.000+0200')
                }

                It "defines 'ServerTime' property with correct value" {
                    $result.ServerTime | Should -Be (Get-Date '2017-09-27T09:59:25.520+0200')
                }

                It "defines 'ScmInfo' property with correct value" {
                    $result.ScmInfo | Should -Be "f3c60100df073e3576f9741fb7a3dc759b416fde"
                }

                It "defines 'ServerTitle' property with correct value" {
                    $result.ServerTitle | Should -Be "JIRA"
                }
            }

            Context "Type Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraServerInfo -InputObject $sampleObject
                }

                It "converts Version to correct type" {
                    $result.Version | Should -BeOfType [String]
                }

                It "converts BuildNumber to numeric type" {
                    $result.BuildNumber | Should -BeOfType ([System.ValueType])
                    $result.BuildNumber.GetType() | Should -BeIn @([int], [long], [int64])
                }

                It "converts BuildDate to correct type" {
                    $result.BuildDate | Should -BeOfType [DateTime]
                }

                It "converts ServerTime to correct type" {
                    $result.ServerTime | Should -BeOfType [DateTime]
                }
            }

            Context "Null Date Handling (Cloud compatibility)" {
                # Some Jira Cloud endpoints omit buildDate and serverTime fields.
                # The converter should return $null instead of throwing.
                # This is a SOFT BREAKING CHANGE: scripts doing
                # (Get-JiraServerInformation).BuildDate.Year will throw
                # NullReferenceException on Cloud.

                BeforeAll {
                    $script:cloudJson = @"
{
    "baseUrl":"https://example.atlassian.net",
    "version":"1001.0.0",
    "versionNumbers":[1001,0,0],
    "deploymentType":"Cloud",
    "buildNumber":100100,
    "scmInfo":"abc123",
    "serverTitle":"JIRA"
}
"@
                    $script:cloudObject = ConvertFrom-Json -InputObject $cloudJson
                    $script:result = ConvertTo-JiraServerInfo -InputObject $cloudObject
                }

                It "returns null for missing BuildDate" {
                    $result.BuildDate | Should -BeNullOrEmpty
                }

                It "returns null for missing ServerTime" {
                    $result.ServerTime | Should -BeNullOrEmpty
                }

                It "still converts other properties correctly" {
                    $result.BaseURL | Should -Be "https://example.atlassian.net"
                    $result.Version | Should -Be "1001.0.0"
                    $result.DeploymentType | Should -Be "Cloud"
                    $result.BuildNumber | Should -Be 100100
                }

                It "does not throw when BuildDate is null" {
                    { ConvertTo-JiraServerInfo -InputObject $cloudObject } | Should -Not -Throw
                }
            }

            Context "Pipeline Support" {
                It "accepts pipeline input" {
                    $result = $sampleObject | ConvertTo-JiraServerInfo
                    $result | Should -Not -BeNullOrEmpty
                }
            }

            Context "Cross-platform expansion fields" {
                It "exposes 'VersionNumbers' as int[] when present" {
                    $payload = ConvertFrom-Json '{"baseUrl":"https://x","version":"9.17.0","versionNumbers":[9,17,0],"buildNumber":1}'
                    $result = ConvertTo-JiraServerInfo -InputObject $payload
                    , $result.VersionNumbers | Should -BeOfType [int[]]
                    $result.VersionNumbers | Should -Be @(9, 17, 0)
                }

                It "leaves 'VersionNumbers' null when the payload omits the field" {
                    $payload = ConvertFrom-Json '{"baseUrl":"https://x","version":"9.17.0","buildNumber":1}'
                    $result = ConvertTo-JiraServerInfo -InputObject $payload
                    $result.VersionNumbers | Should -BeNullOrEmpty
                }

                It "exposes 'DisplayUrl' (DC-only) when the payload provides it" {
                    $payload = ConvertFrom-Json '{"baseUrl":"https://internal","version":"9.17.0","buildNumber":1,"displayUrl":"https://jira.example.com"}'
                    $result = ConvertTo-JiraServerInfo -InputObject $payload
                    $result.DisplayUrl | Should -Be 'https://jira.example.com'
                }
            }
        }
    }
}
