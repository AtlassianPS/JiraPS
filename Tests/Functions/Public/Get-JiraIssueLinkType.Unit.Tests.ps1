#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
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
            $filterAll = { $Method -eq 'Get' -and $Uri -ceq "/rest/api/2/issueLinkType" }
            $filterOne = { $Method -eq 'Get' -and $Uri -ceq "/rest/api/2/issueLinkType/10000" }

            Mock ConvertTo-JiraIssueLinkType {
                Write-MockDebugInfo 'ConvertTo-JiraIssueLinkType'
                # We also don't care what comes out of here - this function has its own tests
                [PSCustomObject] @{
                    PSTypeName = 'JiraPS.IssueLinkType'
                    foo        = 'bar'
                }
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraRequest -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraRequest"
            }

            Mock Invoke-JiraRequest -ParameterFilter $filterAll {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                [PSCustomObject] @{
                    issueLinkTypes = @(
                        # We don't care what data actually comes back here
                        'foo'
                    )
                }
            }

            Mock Invoke-JiraRequest -ParameterFilter $filterOne {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                [PSCustomObject] @{
                    issueLinkTypes = @(
                        'bar'
                    )
                }
            }
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "Returning all link types" {
                It 'Uses Invoke-JiraRequest to communicate with JIRA' {
                    $null = Get-JiraIssueLinkType
                    Should -Invoke Invoke-JiraRequest -ParameterFilter $filterAll -Exactly 1
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
                    Should -Invoke Invoke-JiraRequest -ParameterFilter $filterOne -Exactly 1
                    $output | Should -Not -BeNullOrEmpty
                    @($output) | Should -HaveCount 1
                }

                It 'Returns the correct link type it a type name is passed to the -LinkType parameter' {
                    $output = Get-JiraIssueLinkType -LinkType 'myLink'
                    Should -Invoke Invoke-JiraRequest -ParameterFilter $filterAll -Exactly 1
                    $output | Should -Not -BeNullOrEmpty
                    @($output) | Should -HaveCount 1
                    $output.ID | Should -Be 5
                }
            }
        }

        Describe "Input Validation" {

            Context "Type Validation - Negative Cases" {
                It "uses transformer errors for invalid link type input" {
                    { Get-JiraIssueLinkType -LinkType (Get-Date) -ErrorAction Stop } | Should -Throw -ExpectedMessage "*Cannot convert value of type*IssueLinkType*"
                }
            }
        }
    }
}
