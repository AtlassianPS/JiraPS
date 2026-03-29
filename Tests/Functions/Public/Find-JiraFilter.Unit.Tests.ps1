#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
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
            $script:groupEscaped = ConvertTo-URLEncoded $group
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
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

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

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and
                $URI -like "$jiraServer/rest/api/*/filter/search*"
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $response
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw 'Unidentified call to Invoke-JiraMethod'
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Find-JiraFilter
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "Name"; type = "String[]" }
                    @{ parameter = "AccountId"; type = "String" }
                    @{ parameter = "Owner"; type = "Object" }
                    @{ parameter = "GroupName"; type = "String" }
                    @{ parameter = "Project"; type = "Object" }
                    @{ parameter = "Fields"; type = "String[]" }
                    @{ parameter = "Sort"; type = "String" }
                    @{ parameter = "Credential"; type = "System.Management.Automation.PSCredential" }
                ) {
                    $command | Should -HaveParameter $parameter
                    # Type validation would go here if needed
                }
            }

            Context "Default Values" {}

            Context "Mandatory Parameters" {}
        }

        Describe "Behavior" {
            Context "Filter Search" {
                It "finds a JIRA filter by Name" {
                    { Find-JiraFilter -Name 'Test Filter' } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*/rest/api/*/filter/search*'
                    } -Exactly 1 -Scope It
                }

                It "uses accountId to find JIRA filters if the -AccountId parameter is used" {
                    { Find-JiraFilter -Name 'Test Filter' -AccountId $mockowner.AccountId } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*/rest/api/*/filter/search*' -and
                        $GetParameter['accountId'] -eq $mockOwner.AccountId
                    } -Exactly 1 -Scope It
                }

                It "uses groupName to find JIRA filters if the -GroupName parameter is used" {
                    { Find-JiraFilter -Name 'Test Filter' -GroupName $group } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*/rest/api/*/filter/search*' -and
                        $GetParameter['groupName'] -eq $groupEscaped
                    } -Exactly 1 -Scope It
                }

                It "uses projectId to find JIRA filters if a -Project parameter is used" {
                    { Find-JiraFilter -Name 'Test Filter' -Project 'TEST' } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*/rest/api/*/filter/search*' -and
                        $GetParameter['projectId'] -eq '1'
                    } -Exactly 1 -Scope It
                }

                It "uses orderBy to sort JIRA filters found if the -Sort parameter is used" {
                    { Find-JiraFilter -Name 'Test Filter' -Sort 'name' } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*/rest/api/*/filter/search*' -and
                        $GetParameter['orderBy'] -eq 'name'
                    } -Exactly 1 -Scope It
                }

                It "expands only the fields required with -Fields" {
                    { Find-JiraFilter -Name 'Test Filter' } | Should -Not -Throw
                    { Find-JiraFilter -Name 'Test Filter' -Fields 'description' } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*/rest/api/*/filter/search*' -and
                        $GetParameter['expand'] -eq 'description,favourite,favouritedCount,jql,owner,searchUrl,sharePermissions,subscriptions,viewUrl'
                    } -Exactly 1 -Scope It

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*/rest/api/*/filter/search*' -and
                        $GetParameter['expand'] -eq 'description'
                    } -Exactly 1 -Scope It
                }
            }
        }

        Describe "Input Validation" {
            Context "Parameter Acceptance" {
                It "accepts a project key for the -Project parameter" {
                    { Find-JiraFilter -Project 'Test' } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*/rest/api/*/filter/search*' -and
                        $GetParameter['projectId'] -eq '1'
                    } -Exactly 1 -Scope It
                }

                It "accepts AccountId, GroupName, and Project parameter values from pipeline by property name" {
                    $searchObject = [PSCustomObject]@{
                        AccountId = $mockowner.AccountId
                        GroupName = $group
                        Project   = 'Test'
                    }

                    { $searchObject | Find-JiraFilter } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*/rest/api/*/filter/search*' -and
                        $GetParameter['accountId'] -eq $mockowner.AccountId -and
                        $GetParameter['groupName'] -eq $groupEscaped -and
                        $GetParameter['projectId'] -eq '1'
                    } -Exactly 1 -Scope It
                }

                It "accepts a user object for the -Owner parameter" {
                    { Find-JiraFilter -Owner $mockowner.Name } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*/rest/api/*/filter/search*'
                    } -Exactly 1 -Scope It

                    Should -Invoke Get-JiraUser -ModuleName JiraPS -ParameterFilter {
                        $InputObject -eq $mockOwner.Name
                    } -Exactly 1 -Scope It
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
