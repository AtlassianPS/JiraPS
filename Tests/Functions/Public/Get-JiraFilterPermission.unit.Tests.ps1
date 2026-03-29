#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Get-JiraFilterPermission" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = "https://jira.example.com"

            $script:sampleResponse = @"
{
  "id": 10000,
  "type": "global"
}
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock ConvertTo-JiraFilter -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraFilter'
            }

            Mock Get-JiraFilter -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraFilter' 'Id'
                foreach ($_id in $Id) {
                    $basicFilter = New-Object -TypeName PSCustomObject -Property @{
                        Id      = $_id
                        RestUrl = "$jiraServer/rest/api/2/filter/$_id"
                    }
                    $basicFilter.PSObject.TypeNames.Insert(0, 'JiraPS.Filter')
                    $basicFilter
                }
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/filter/*/permission" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $sampleResponse
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
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
            Context "Behavior testing" {
                It "Retrieves the permissions of a Filter by Object" {
                    { Get-JiraFilter -Id 23456 | Get-JiraFilterPermission } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*/rest/api/*/filter/23456/permission'
                    }
                }

                It "Retrieves the permissions of a Filter by Id" {
                    { 23456 | Get-JiraFilterPermission } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*/rest/api/*/filter/23456/permission'
                    }
                }
            }

            Context "Input testing" {
                It "finds the filter by Id" {
                    { Get-JiraFilterPermission -Id 23456 } | Should -Not -Throw

                    Should -Invoke Get-JiraFilter -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "does not accept negative Ids" {
                    { Get-JiraFilterPermission -Id -1 } | Should -Throw
                }

                It "can process multiple Ids" {
                    { Get-JiraFilterPermission -Id 23456, 23456 } | Should -Not -Throw

                    Should -Invoke Get-JiraFilter -ModuleName JiraPS -Exactly -Times 1 -Scope It
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -Scope It
                }

                It "allows for the filter to be passed over the pipeline" {
                    { Get-JiraFilter -Id 23456 | Get-JiraFilterPermission } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "can ony process one Filter objects" {
                    $filter = @()
                    $filter += Get-JiraFilter -Id 23456
                    $filter += Get-JiraFilter -Id 23456

                    { Get-JiraFilterPermission -Filter $filter } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -Scope It
                }

                It "resolves positional parameters" {
                    { Get-JiraFilterPermission 23456 } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It

                    $filter = Get-JiraFilter -Id 23456
                    { Get-JiraFilterPermission $filter } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -Scope It
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
