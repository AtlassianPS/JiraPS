#requires -modules BuildHelpers
#requires -modules @{ ModuleName = 'Pester'; ModuleVersion = '4.4.0' }

Describe 'Find-JiraFilter' -Tag 'Unit' {

    BeforeAll {
        Remove-Item -Path Env:\BH*
        $projectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        if ($projectRoot -like '*Release') {
            $projectRoot = (Resolve-Path "$projectRoot/..").Path
        }

        Import-Module BuildHelpers
        Set-BuildEnvironment -BuildOutput '$ProjectPath/Release' -Path $projectRoot -ErrorAction SilentlyContinue

        $env:BHManifestToTest = $env:BHPSModuleManifest
        $script:isBuild = $PSScriptRoot -like "$env:BHBuildOutput*"
        if ($script:isBuild) {
            $Pattern = [regex]::Escape($env:BHProjectPath)

            $env:BHBuildModuleManifest = $env:BHPSModuleManifest -replace $Pattern, $env:BHBuildOutput
            $env:BHManifestToTest = $env:BHBuildModuleManifest
        }

        Import-Module "$env:BHProjectPath/Tools/BuildTools.psm1"

        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Import-Module $env:BHManifestToTest
    }
    AfterAll {
        Remove-Module $env:BHProjectName -ErrorAction SilentlyContinue
        Remove-Module BuildHelpers -ErrorAction SilentlyContinue
        Remove-Item -Path Env:\BH*
    }

    InModuleScope JiraPS {

        . "$PSScriptRoot/../Shared.ps1"

        $mockOwner = [PSCustomObject]@{
            AccountId = 'c62dde3418235be1c8424950'
            Name = 'TUser1'
        }
        $group = 'groupA'
        $groupEscaped = ConvertTo-URLEncoded $group
        $response = @'
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

        #region Mocks

        Mock Get-JiraProject -ModuleName JiraPS {
            ShowMockInfo 'Get-JiraProject' 'Project'
            [PSCustomObject]@{
                Id = '1'
                Key = 'Test'
            }
        }

        Mock Get-JiraUser -ModuleName JiraPS {
            ShowMockInfo 'Get-JiraUser' 'User'
            $mockOwner
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
            $Method -eq 'Get' -and
            $URI -like "rest/api/*/filter/search*"
        } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $response
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw 'Unidentified call to Invoke-JiraMethod'
        }
        #endregion Mocks

        Context 'Sanity checking' {
            $command = Get-Command -Name Find-JiraFilter

            defParam $command 'Name'
            defParam $command 'AccountId'
            defParam $command 'Owner'
            defParam $command 'GroupName'
            defParam $command 'Project'
            defParam $command 'Fields'
            defParam $command 'Sort'
            defParam $command 'Session'
        }

        Context 'Behavior testing' {

            It 'Finds a JIRA filter by Name' {
                { Find-JiraFilter -Name 'Test Filter' } | Should -Not -Throw

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Method -eq 'Get' -and
                        $URI -like 'rest/api/*/filter/search*'
                    }
                    Scope           = 'It'
                    Exactly         = $true
                    Times           = 1
                }
                Assert-MockCalled @assertMockCalledSplat
            }

            It 'Uses accountId to find JIRA filters if the -AccountId parameter is used' {
                { Find-JiraFilter -Name 'Test Filter' -AccountId $mockowner.AccountId } | Should -Not -Throw

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Method -eq 'Get' -and
                        $URI -like 'rest/api/*/filter/search*' -and
                        $GetParameter['accountId'] -eq $mockOwner.AccountId
                    }
                    Scope           = 'It'
                    Exactly         = $true
                    Times           = 1
                }
                Assert-MockCalled @assertMockCalledSplat
            }

            It 'Uses groupName to find JIRA filters if the -GroupName parameter is used' {
                { Find-JiraFilter -Name 'Test Filter' -GroupName $group } | Should -Not -Throw

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Method -eq 'Get' -and
                        $URI -like 'rest/api/*/filter/search*' -and
                        $GetParameter['groupName'] -eq $groupEscaped
                    }
                    Scope           = 'It'
                    Exactly         = $true
                    Times           = 1
                }
                Assert-MockCalled @assertMockCalledSplat
            }

            It 'Uses projectId to find JIRA filters if a -Project parameter is used' {
                { Find-JiraFilter -Name 'Test Filter' -Project 'TEST' } | Should -Not -Throw

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Method -eq 'Get' -and
                        $URI -like 'rest/api/*/filter/search*' -and
                        $GetParameter['projectId'] -eq '1'
                    }
                    Scope           = 'It'
                    Exactly         = $true
                    Times           = 1
                }
                Assert-MockCalled @assertMockCalledSplat
            }

            It 'Uses orderBy to sort JIRA filters found if the -Sort parmaeter is used' {
                { Find-JiraFilter -Name 'Test Filter' -Sort 'name' } | Should -Not -Throw

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Method -eq 'Get' -and
                        $URI -like 'rest/api/*/filter/search*' -and
                        $GetParameter['orderBy'] -eq 'name'
                    }
                    Scope           = 'It'
                    Exactly         = $true
                    Times           = 1
                }
                Assert-MockCalled @assertMockCalledSplat
            }

            It 'Expands only the fields required with -Fields' {
                { Find-JiraFilter -Name 'Test Filter' } | Should -Not -Throw
                { Find-JiraFilter -Name 'Test Filter' -Fields 'description' } | Should -Not -Throw

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Method -eq 'Get' -and
                        $URI -like 'rest/api/*/filter/search*' -and
                        $GetParameter['expand'] -eq 'description,favourite,favouritedCount,jql,owner,searchUrl,sharePermissions,subscriptions,viewUrl'
                    }
                    Scope           = 'It'
                    Exactly         = $true
                    Times           = 1
                }
                Assert-MockCalled @assertMockCalledSplat

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Method -eq 'Get' -and
                        $URI -like 'rest/api/*/filter/search*' -and
                        $GetParameter['expand'] -eq 'description'
                    }
                    Scope           = 'It'
                    Exactly         = $true
                    Times           = 1
                }
                Assert-MockCalled @assertMockCalledSplat
            }
        }

        Context 'Input testing' {
            It 'Accepts a project key for the -Project parameter' {
                { Find-JiraFilter -Project 'Test' } | Should -Not -Throw

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Method -eq 'Get' -and
                        $URI -like 'rest/api/*/filter/search*' -and
                        $GetParameter['projectId'] -eq '1'
                    }
                    Scope           = 'It'
                    Exactly         = $true
                    Times           = 1
                }
                Assert-MockCalled @assertMockCalledSplat
            }

            It 'Accepts AccountId, GroupName, and Project parameter values from pipeline by property name' {
                $searchObject = [PSCustomObject]@{
                    AccountId = $mockowner.AccountId
                    GroupName = $group
                    Project = 'Test'
                }

                # Should call Find-JiraFilter using the -Key parameter, so our URL should reflect the key we provided
                { $searchObject | Find-JiraFilter } | Should -Not -Throw

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Method -eq 'Get' -and
                        $URI -like 'rest/api/*/filter/search*' -and
                        $GetParameter['accountId'] -eq $mockowner.AccountId -and
                        $GetParameter['groupName'] -eq $groupEscaped -and
                        $GetParameter['projectId'] -eq '1'
                    }
                    Scope           = 'It'
                    Exactly         = $true
                    Times           = 1
                }
                Assert-MockCalled @assertMockCalledSplat
            }

            It 'Accepts a user object for the -Owner parameter' {
                { Find-JiraFilter -Owner $mockowner.Name } | Should -Not -Throw

                $assertMockCalledSplat1 = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Method -eq 'Get' -and
                        $URI -like 'rest/api/*/filter/search*' #-and
                        $GetParameter['AccountId'] -eq $mockOwner.AccountId
                    }
                    Scope           = 'It'
                    Exactly         = $true
                    Times           = 1
                }
                Assert-MockCalled @assertMockCalledSplat1

                $assertMockCalledSplat2 = @{
                    CommandName     = 'Get-JiraUser'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $InputObject -eq $mockOwner.Name
                    }
                    Scope           = 'It'
                    Exactly         = $true
                    Times           = 1
                }
                Assert-MockCalled @assertMockCalledSplat2
            }
        }
    }
}
