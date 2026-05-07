#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Get-JiraStatus" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:jiraServer = 'https://jira.example.com'

            $script:restResultAll = @"
[
    {
        "self": "$jiraServer/rest/api/2/status/1",
        "description": "Issue is open",
        "iconUrl": "$jiraServer/images/icons/statuses/open.png",
        "name": "Open",
        "id": "1"
    }
]
"@

            $script:restResultOne = @"
{
    "self": "$jiraServer/rest/api/2/status/1",
    "description": "Issue is open",
    "iconUrl": "$jiraServer/images/icons/statuses/open.png",
    "name": "Open",
    "id": "1"
}
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock ConvertTo-JiraStatus -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraStatus'
                $InputObject
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'GET' -and
                $URI -eq "$jiraServer/rest/api/latest/status"
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $restResultAll
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'GET' -and
                $URI -eq "$jiraServer/rest/api/latest/status/1"
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $restResultOne
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'GET' -and
                $URI -eq "$jiraServer/rest/api/latest/status/Open"
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $restResultOne
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Behavior" {
            It "gets all statuses when no -Status value is provided" {
                $result = Get-JiraStatus

                $result | Should -Not -BeNullOrEmpty
                @($result) | Should -HaveCount 1

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'GET' -and
                    $URI -eq "$jiraServer/rest/api/latest/status"
                }
            }

            It "gets one status when -Status is provided" {
                $result = Get-JiraStatus -Status 1

                $result | Should -Not -BeNullOrEmpty
                @($result) | Should -HaveCount 1

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'GET' -and
                    $URI -eq "$jiraServer/rest/api/latest/status/1"
                }
            }

            It "processes multiple -Status values" {
                $result = Get-JiraStatus -Status 1, Open

                $result | Should -Not -BeNullOrEmpty
                @($result) | Should -HaveCount 2

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'GET' -and
                    $URI -eq "$jiraServer/rest/api/latest/status/1"
                }

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'GET' -and
                    $URI -eq "$jiraServer/rest/api/latest/status/Open"
                }
            }

            It "accepts pipeline input for -Status" {
                { '1' | Get-JiraStatus } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'GET' -and
                    $URI -eq "$jiraServer/rest/api/latest/status/1"
                }
            }

            It "accepts -IdOrName as an alias for -Status" {
                $result = Get-JiraStatus -IdOrName Open

                $result | Should -Not -BeNullOrEmpty
                @($result) | Should -HaveCount 1

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'GET' -and
                    $URI -eq "$jiraServer/rest/api/latest/status/Open"
                }
            }
        }
    }
}
