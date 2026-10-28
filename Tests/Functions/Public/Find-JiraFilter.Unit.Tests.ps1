#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Find-JiraFilter" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'https://jira.example.com'

            $script:mockOwner = [PSCustomObject]@{
                AccountId = 'c62dde3418235be1c8424950'
                Name      = 'TUser1'
            }
            $script:group = 'groupA'
            $script:response = @'
{
    'expand': 'schema,names',
    'startAt': 0,
    'maxResults': 25,
    'total': 1,
    'filters': [
        {
            "SearchUrl": "https://jira.example.com/rest/api/2/search?jql=id+in+(TEST-001,+TEST-002,+TEST-003)",
            "ID": "1",
            "FilterPermissions": [],
            "Name": "Test filter",
            "JQL": "id in (TEST-001, TEST-002, TEST-003)",
            "SharePermission": {
                "project": {
                    "id": 1,
                    "key": 'Test'
                }
            },
            "Owner": {
                "Name": "TUser1",
                "AccountId": "c62dde3418235be1c8424950"
            },
            "Favourite": true,
            "Description": "This is a test filter",
            "RestUrl": "https://jira.example.com/rest/api/2/filter/1",
            "ViewUrl": "https://jira.example.com/issues/?filter=1",
            "Favorite": true
        }
    ]
}
'@
            #endregion Definitions

            #region Mocks
            Mock Test-JiraCloudServer { $true }
            Mock Get-JiraProject -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraProject' 'Project'
                [PSCustomObject]@{
                    Id  = '1'
                    Key = 'Test'
                }
            }

            Mock Get-JiraUser -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraUser' 'InputObject'
                $mockOwner
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -like "*rest/api/*/filter/search*"
            } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                ConvertFrom-Json $response
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                throw 'Unidentified call to Invoke-JiraRequest'
            }
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "Filter Search" {
                It "finds a JIRA filter by Name" {
                    { Find-JiraFilter -Name 'Test Filter' } | Should -Not -Throw

                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*rest/api/*/filter/search*'
                    } -Exactly 1
                }

                It "uses accountId to find JIRA filters if the -AccountId parameter is used" {
                    { Find-JiraFilter -Name 'Test Filter' -AccountId $mockowner.AccountId } | Should -Not -Throw

                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*rest/api/*/filter/search*' -and
                        $GetParameter['accountId'] -eq $mockOwner.AccountId
                    } -Exactly 1
                }

                It "uses groupName to find JIRA filters if the -GroupName parameter is used" {
                    { Find-JiraFilter -Name 'Test Filter' -GroupName $group } | Should -Not -Throw

                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*rest/api/*/filter/search*' -and
                        $GetParameter['groupName'] -eq $group
                    } -Exactly 1
                }

                It "uses projectId to find JIRA filters if a -Project parameter is used" {
                    { Find-JiraFilter -Name 'Test Filter' -Project 'TEST' } | Should -Not -Throw

                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*rest/api/*/filter/search*' -and
                        $GetParameter['projectId'] -eq '1'
                    } -Exactly 1
                }

                It "uses orderBy to sort JIRA filters found if the -Sort parameter is used" {
                    { Find-JiraFilter -Name 'Test Filter' -Sort 'name' } | Should -Not -Throw

                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*rest/api/*/filter/search*' -and
                        $GetParameter['orderBy'] -eq 'name'
                    } -Exactly 1
                }

                It "expands only the fields required with -Fields" {
                    { Find-JiraFilter -Name 'Test Filter' } | Should -Not -Throw
                    { Find-JiraFilter -Name 'Test Filter' -Fields 'description' } | Should -Not -Throw

                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*rest/api/*/filter/search*' -and
                        $GetParameter['expand'] -eq 'description,favourite,favouritedCount,jql,owner,searchUrl,sharePermissions,subscriptions,viewUrl'
                    } -Exactly 1

                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*rest/api/*/filter/search*' -and
                        $GetParameter['expand'] -eq 'description'
                    } -Exactly 1
                }
            }
        }

        Describe "Input Validation" {
            Context "Parameter Acceptance" {

                It "accepts AccountId, GroupName, and Project parameter values from pipeline by property name" {
                    $searchObject = [PSCustomObject]@{
                        AccountId = $mockowner.AccountId
                        GroupName = $group
                        Project   = 'Test'
                    }

                    { $searchObject | Find-JiraFilter } | Should -Not -Throw

                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*rest/api/*/filter/search*' -and
                        $GetParameter['accountId'] -eq $mockowner.AccountId -and
                        $GetParameter['groupName'] -eq $group -and
                        $GetParameter['projectId'] -eq '1'
                    } -Exactly 1
                }

                It "accepts a user object for the -Owner parameter" {
                    { Find-JiraFilter -Owner $mockowner.Name } | Should -Not -Throw

                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*rest/api/*/filter/search*'
                    } -Exactly 1

                    Should -Invoke Get-JiraUser -ModuleName JiraPS -ParameterFilter {
                        $User.Name -contains $mockOwner.Name
                    } -Exactly 1
                }
            }
        }

    }
}
