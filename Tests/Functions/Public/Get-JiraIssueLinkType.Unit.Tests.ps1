#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Get-JiraIssueLinkType" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            #endregion Definitions


            #region Mocks
            $filterAll = { $Method -eq 'Get' -and $Uri -ceq "$jiraServer/rest/api/2/issueLinkType" }
            $filterOne = { $Method -eq 'Get' -and $Uri -ceq "$jiraServer/rest/api/2/issueLinkType/10000" }

            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock ConvertTo-JiraIssueLinkType {
                Write-MockDebugInfo 'ConvertTo-JiraIssueLinkType'
                # We also don't care what comes out of here - this function has its own tests
                [PSCustomObject] @{
                    PSTypeName = 'JiraPS.IssueLinkType'
                    foo        = 'bar'
                }
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }

            Mock Invoke-JiraMethod -ParameterFilter $filterAll {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                [PSCustomObject] @{
                    issueLinkTypes = @(
                        # We don't care what data actually comes back here
                        'foo'
                    )
                }
            }

            Mock Invoke-JiraMethod -ParameterFilter $filterOne {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                [PSCustomObject] @{
                    issueLinkTypes = @(
                        'bar'
                    )
                }
            }
            #endregion Mocks
        }

        Describe "Signature" {
            Context "Parameter Types" {
                # TODO: Add parameter type validation tests
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            Context "Returning all link types" {
                It 'Uses Invoke-JiraMethod to communicate with JIRA' {
                    $null = Get-JiraIssueLinkType
                    Should -Invoke Invoke-JiraMethod -ParameterFilter $filterAll -Exactly 1
                }

                It 'Returns all link types if no value is passed to the -LinkType parameter' {
                    $output = Get-JiraIssueLinkType
                    $output | Should -Not -BeNullOrEmpty
                }

                It 'Uses the helper method ConvertTo-JiraIssueLinkType to process output' {
                    $null = Get-JiraIssueLinkType
                    Should -Invoke ConvertTo-JiraIssueLinkType -ParameterFilter { $InputObject -contains 'foo' } -Exactly 1
                }
            }

            Context "Returning one link type" {
                BeforeAll {
                    Mock ConvertTo-JiraIssueLinkType {
                        Write-MockDebugInfo 'ConvertTo-JiraIssueLinkType'
                        # We also don't care what comes out of here - this function has its own tests
                        [PSCustomObject] @{
                            PSTypeName = 'JiraPS.IssueLinkType'
                            Name       = 'myLink'
                            ID         = 5
                        }
                    }
                }

                It 'Returns a single link type if an ID number is passed to the -LinkType parameter' {
                    $output = Get-JiraIssueLinkType -LinkType 10000
                    Should -Invoke Invoke-JiraMethod -ParameterFilter $filterOne -Exactly 1
                    $output | Should -Not -BeNullOrEmpty
                    @($output) | Should -HaveCount 1
                }

                It 'Returns the correct link type it a type name is passed to the -LinkType parameter' {
                    $output = Get-JiraIssueLinkType -LinkType 'myLink'
                    Should -Invoke Invoke-JiraMethod -ParameterFilter $filterAll -Exactly 1
                    $output | Should -Not -BeNullOrEmpty
                    @($output) | Should -HaveCount 1
                    $output.ID | Should -Be 5
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
