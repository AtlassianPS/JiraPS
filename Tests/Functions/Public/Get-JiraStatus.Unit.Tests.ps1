#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

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
            Mock ConvertTo-JiraStatus -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraStatus'
                $InputObject
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'GET' -and
                $URI -eq "/rest/api/latest/status"
            } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                ConvertFrom-Json $restResultAll
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'GET' -and
                $URI -eq "/rest/api/latest/status/1"
            } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                ConvertFrom-Json $restResultOne
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'GET' -and
                $URI -eq "/rest/api/latest/status/Open"
            } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                ConvertFrom-Json $restResultOne
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraRequest"
            }
            #endregion Mocks
        }

        Describe "Behavior" {
            It "gets all statuses when no -Status value is provided" {
                $result = Get-JiraStatus

                $result | Should -Not -BeNullOrEmpty
                @($result) | Should -HaveCount 1

                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'GET' -and
                    $URI -eq "/rest/api/latest/status"
                }
            }

            It "gets one status when -Status is provided" {
                $result = Get-JiraStatus -Status 1

                $result | Should -Not -BeNullOrEmpty
                @($result) | Should -HaveCount 1

                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'GET' -and
                    $URI -eq "/rest/api/latest/status/1"
                }
            }

            It "escapes a status name as one URI path segment" {
                Mock Invoke-JiraRequest -ModuleName JiraPS {
                    ConvertFrom-Json $restResultOne
                } -ParameterFilter {
                    $Method -eq 'GET' -and
                    $URI -eq "/rest/api/latest/status/In%20Progress%2FQA%3F%23"
                }

                Get-JiraStatus -Status 'In Progress/QA?#' | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'GET' -and
                    $URI -eq "/rest/api/latest/status/In%20Progress%2FQA%3F%23"
                }
            }

            It "prefers the ID when a status object also contains a name" {
                $status = [AtlassianPS.JiraPS.Status]@{ Id = 1; Name = 'Open' }

                Get-JiraStatus -Status $status | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $URI -eq "/rest/api/latest/status/1"
                }
            }

            It "processes multiple -Status values" {
                $result = Get-JiraStatus -Status 1, Open

                $result | Should -Not -BeNullOrEmpty
                @($result) | Should -HaveCount 2

                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'GET' -and
                    $URI -eq "/rest/api/latest/status/1"
                }

                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'GET' -and
                    $URI -eq "/rest/api/latest/status/Open"
                }
            }

            It "accepts pipeline input for -Status" {
                { '1' | Get-JiraStatus } | Should -Not -Throw

                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'GET' -and
                    $URI -eq "/rest/api/latest/status/1"
                }
            }

            It "accepts -IdOrName as an alias for -Status" {
                $result = Get-JiraStatus -IdOrName Open

                $result | Should -Not -BeNullOrEmpty
                @($result) | Should -HaveCount 1

                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'GET' -and
                    $URI -eq "/rest/api/latest/status/Open"
                }
            }
        }
    }
}
