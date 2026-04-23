#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
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
            Mock Test-JiraCloudServer -ModuleName JiraPS { $false }

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

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*/rest/api/*/issue/TEST-001*'
                    }
                }

                It "Uses JQL to search for issues if the -Query parameter is used" {
                    { Get-JiraIssue -Query $jql } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like "*/rest/api/*/search" -and
                        $GetParameter["jql"] -eq $jqlEscaped
                    }
                }

                It "Supports the -Skip and -First paging parameters to page through search results" {
                    { Get-JiraIssue -Query $jql -Skip 10 -First 50 } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like "*/rest/api/*/search" -and
                        $GetParameter["jql"] -eq $jqlEscaped -and
                        $Skip -eq 10 -and
                        $First -eq 50
                    }
                }

                It "Returns all issues via looping if -MaxResults is not specified" {
                    { Get-JiraIssue -Query $jql -PageSize 25 } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
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

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Get' -and
                        $GetParameter["fields"] -eq "*all"
                    }

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Get' -and
                        $GetParameter["fields"] -eq "key"
                    }

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Get' -and
                        $GetParameter["fields"] -eq "-summary"
                    }

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 4 -ParameterFilter {
                        $Method -eq 'Get' -and
                        $GetParameter["fields"] -eq "key,summary,status"
                    }
                }
            }

            Context "Input testing" {
                It "Accepts an issue key for the -Key parameter" {
                    { Get-JiraIssue -Key TEST-001 } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
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

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like "*/rest/api/*/issue/TEST-001*"
                    }
                }

                It "Accepts an issue object via pipeline using ValueFromPipelineByPropertyName" {
                    $issue = [PSCustomObject] @{
                        'Key' = 'TEST-001'
                        'ID'  = '12345'
                    }
                    $issue.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')

                    # Pipeline input binds Key property to -Key parameter via ValueFromPipelineByPropertyName
                    { $issue | Get-JiraIssue } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like "*/rest/api/*/issue/TEST-001*"
                    }
                }
            }

            Context "Pipeline binding regression tests" {
                # These tests verify the parameter set resolution behavior after adding
                # ValueFromPipelineByPropertyName to -Key. This is a soft breaking change:
                # objects with a Key property now bind to ByIssueKey instead of failing.

                It "Binds JiraPS.Issue via pipeline to ByIssueKey parameter set" {
                    $issue = [PSCustomObject] @{
                        'Key' = 'TEST-001'
                        'ID'  = '12345'
                    }
                    $issue.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')

                    # The Key property should bind to -Key via ValueFromPipelineByPropertyName
                    $issue | Get-JiraIssue

                    # Verify API was called with the key
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $URI -like "*/rest/api/*/issue/TEST-001*"
                    }
                }

                It "Binds generic PSCustomObject with Key property to ByIssueKey parameter set" {
                    # BEHAVIOR CHANGE: Previously this would fail because no parameter
                    # accepted pipeline input. Now the Key property binds to -Key.
                    $obj = [PSCustomObject]@{ Key = 'TEST-001' }

                    { $obj | Get-JiraIssue } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $URI -like "*/rest/api/*/issue/TEST-001*"
                    }
                }

                It "Processes multiple issues via pipeline" {
                    $issues = @(
                        [PSCustomObject]@{ Key = 'TEST-001' }
                        [PSCustomObject]@{ Key = 'TEST-001' }  # Same key, should call twice
                    )
                    $issues | ForEach-Object { $_.PSObject.TypeNames.Insert(0, 'JiraPS.Issue') }

                    { $issues | Get-JiraIssue } | Should -Not -Throw

                    # Should be called once per piped object
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -ParameterFilter {
                        $URI -like "*/rest/api/*/issue/TEST-001*"
                    }
                }

                It "Explicit -InputObject still works with JiraPS.Issue objects" {
                    # Verify the ByInputObject parameter set still functions when used explicitly
                    $issue = [PSCustomObject] @{
                        'Key' = 'TEST-001'
                        'ID'  = '12345'
                    }
                    $issue.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')

                    { Get-JiraIssue -InputObject $issue } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $URI -like "*/rest/api/*/issue/TEST-001*"
                    }
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }

        Describe "Cloud Deployment" {
            BeforeAll {
                Mock Test-JiraCloudServer -ModuleName JiraPS { $true }

                Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like "$jiraServer/rest/api/3/search/jql*"
                } {
                    Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                    ConvertFrom-Json $response
                }

                Mock Invoke-JiraMethod -ModuleName JiraPS {
                    Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                    throw "Unidentified call to Invoke-JiraMethod"
                }
            }

            It "uses the v3 search endpoint for JQL queries on Cloud" {
                { Get-JiraIssue -Query $jql } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -like "$jiraServer/rest/api/3/search/jql*"
                }
            }
        }
    }
}
