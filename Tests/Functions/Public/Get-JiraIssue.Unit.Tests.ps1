#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Get-JiraIssue" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = "https://jira.example.com"
            $script:jql = 'reporter in (testuser)'
            $script:jqlEscaped = ConvertTo-URLEncoded $jql
            $script:response = @'
{
    "expand": "schema,names",
    "startAt": 0,
    "maxResults": 25,
    "total": 1,
    "issues": [
        {
            "key": "TEST-001",
            "fields": {
                "summary": "Test summary"
            }
        }
    ]
}
'@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Get-JiraUser -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraUser'
                $object = [PSCustomObject] @{
                    'Name' = 'username'
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.User')
                return $object
            }

            Mock Get-JiraFilter -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraFilter'
                [PSCustomObject]@{
                    PSTypeName = "JiraPS.Filter"
                    Id         = 12345
                    SearchUrl  = "https://jira.example.com/rest/api/2/filter/12345"
                }
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -like "$jiraServer/rest/api/*/issue/TEST-001*"
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $response
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -like "$jiraServer/rest/api/*/search" -and
                $GetParameter["jql"] -eq $jqlEscaped
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $response
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -like "$jiraServer/rest/api/*/filter/*"
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $response
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
                It "Obtains information about a provided issue in JIRA" {
                    { Get-JiraIssue -Key TEST-001 } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*/rest/api/*/issue/TEST-001*'
                    }
                }

                It "Uses JQL to search for issues if the -Query parameter is used" {
                    { Get-JiraIssue -Query $jql } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like "*/rest/api/*/search" -and
                        $GetParameter["jql"] -eq $jqlEscaped
                    }
                }

                It "Supports the -StartIndex and -MaxResults parameters to page through search results" {
                    { Get-JiraIssue -Query $jql -StartIndex 10 -MaxResults 50 } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like "*/rest/api/*/search" -and
                        $GetParameter["jql"] -eq $jqlEscaped -and
                        $PSCmdlet.PagingParameters.Skip -eq 10
                        $PSCmdlet.PagingParameters.First -eq 50
                    }
                }

                It "Returns all issues via looping if -MaxResults is not specified" {
                    { Get-JiraIssue -Query $jql -PageSize 25 } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like "*/rest/api/*/search" -and
                        $GetParameter["jql"] -eq $jqlEscaped -and
                        $GetParameter["maxResults"] -eq 25
                    }
                }

                It "Returns only the fields required with -Fields" {
                    $issue = [PSCustomObject]@{
                        PSTypeName = "JiraPS.Issue"
                        Key        = "TEST-001"
                    }

                    { Get-JiraIssue -Key TEST-001 } | Should -Not -Throw
                    { Get-JiraIssue -Key TEST-001 -Fields "key" } | Should -Not -Throw
                    { Get-JiraIssue -Key TEST-001 -Fields "-summary" } | Should -Not -Throw
                    { Get-JiraIssue -Key TEST-001 -Fields "key", "summary", "status" } | Should -Not -Throw
                    { Get-JiraIssue -InputObject $issue -Fields "key", "summary", "status" } | Should -Not -Throw
                    { Get-JiraIssue -Query $jql -Fields "key", "summary", "status" } | Should -Not -Throw
                    { Get-JiraIssue -Filter "12345" -Fields "key", "summary", "status" } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Get' -and
                        $GetParameter["fields"] -eq "*all"
                    }

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Get' -and
                        $GetParameter["fields"] -eq "key"
                    }

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Get' -and
                        $GetParameter["fields"] -eq "-summary"
                    }

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 4 -Scope It -ParameterFilter {
                        $Method -eq 'Get' -and
                        $GetParameter["fields"] -eq "key,summary,status"
                    }
                }
            }

            Context "Input testing" {
                It "Accepts an issue key for the -Key parameter" {
                    { Get-JiraIssue -Key TEST-001 } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like "*/rest/api/*/issue/TEST-001*"
                    }
                }

                It "Accepts an issue object for the -InputObject parameter" {
                    $issue = [PSCustomObject] @{
                        'Key' = 'TEST-001'
                        'ID'  = '12345'
                    }
                    $issue.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')

                    # Should call Get-JiraIssue using the -Key parameter, so our URL should reflect the key we provided
                    { Get-JiraIssue -InputObject $Issue } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like "*/rest/api/*/issue/TEST-001*"
                    }
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
