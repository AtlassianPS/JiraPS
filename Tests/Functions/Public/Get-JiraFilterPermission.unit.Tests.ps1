#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Nonsecret unit-test credential fixture.')]
param()

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
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
            Mock ConvertTo-JiraFilter -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraFilter'
            }

            Mock Get-JiraFilter -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraFilter' 'InputObject'
                foreach ($item in $Filter) {
                    [AtlassianPS.JiraPS.Filter]@{
                        Id      = $item.Id
                        RestUrl = "$jiraServer/rest/api/2/filter/$($item.Id)"
                    }
                }
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/filter/*/permission" } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                ConvertFrom-Json $sampleResponse
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraRequest"
            }
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "Typed references and aliases" {
                It "accepts arrays through '<parameter>'" -TestCases @(
                    @{ parameter = 'Filter' }
                    @{ parameter = 'Id' }
                ) {
                    param($parameter)
                    $arguments = @{ $parameter = @('12345', '67890') }
                    Get-JiraFilterPermission @arguments

                    Should -Invoke Invoke-JiraRequest -Exactly -Times 2
                }

                It "accepts numeric strings from the pipeline" {
                    '12345', '67890' | Get-JiraFilterPermission

                    Should -Invoke Invoke-JiraRequest -Exactly -Times 2
                }

                It "accepts a complete typed filter from the pipeline" {
                    $filter = [AtlassianPS.JiraPS.Filter]@{
                        Id      = '12345'
                        Name    = 'Test filter'
                        RestUrl = "$jiraServer/rest/api/2/filter/12345"
                    }
                    $filter | Get-JiraFilterPermission

                    Should -Invoke Invoke-JiraRequest -Exactly -Times 1
                }
            }

            Context "Behavior testing" {

                It "Retrieves the permissions of a Filter by Object" {
                    { Get-JiraFilter -Id 23456 | Get-JiraFilterPermission } | Should -Not -Throw

                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*/rest/api/*/filter/23456/permission'
                    }
                }

                It "Retrieves the permissions of a Filter by Id" {
                    { 23456 | Get-JiraFilterPermission } | Should -Not -Throw

                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*/rest/api/*/filter/23456/permission'
                    }
                }
            }

            Context "Input testing" {
                It "does not accept negative Ids" {
                    { Get-JiraFilterPermission -Id -1 } | Should -Throw -ExpectedMessage "*positive numeric ID*"
                }

                It "can process multiple Ids" {
                    { Get-JiraFilterPermission -Id 23456, 23456 } | Should -Not -Throw

                    Should -Invoke Get-JiraFilter -ModuleName JiraPS -Exactly -Times 2
                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 2
                }

                It "can only process one Filter objects" {
                    $filter = @()
                    $filter += Get-JiraFilter -Id 23456
                    $filter += Get-JiraFilter -Id 23456

                    { Get-JiraFilterPermission -Filter $filter } | Should -Not -Throw

                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 2
                }

                It "resolves positional parameters" {
                    { Get-JiraFilterPermission 23456 } | Should -Not -Throw

                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1

                    $filter = Get-JiraFilter -Id 23456
                    { Get-JiraFilterPermission $filter } | Should -Not -Throw

                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 2
                }
            }
        }

    }
}
