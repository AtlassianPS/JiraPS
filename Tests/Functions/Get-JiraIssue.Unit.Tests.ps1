#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe "Get-JiraGroupMember" -Tag 'Unit' {

    BeforeAll {
        Remove-Item -Path Env:\BH*
        $projectRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        if ($projectRoot -like "*Release") {
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

        $jiraServer = "https://jira.example.com"

        $jql = 'reporter in (testuser)'
        $jqlEscaped = ConvertTo-URLEncoded $jql
        $response = @'
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

        #region Mocks
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            $jiraServer
        }

        Mock Get-JiraUser -ModuleName JiraPS {
            $object = [PSCustomObject] @{
                'Name' = 'username'
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.User')
            return $object
        }

        Mock Get-JiraFilter -ModuleName JiraPS {
            [PSCustomObject]@{
                PSTypeName = "JiraPS.Filter"
                Id         = 12345
                SearchUrl  = "https://jira.example.com/rest/api/latest/filter/12345"
            }
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
            $Method -eq 'Get' -and
            $URI -like "$jiraServer/rest/api/*/issue/TEST-001*"
        } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $response
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
            $Method -eq 'Get' -and
            $URI -like "$jiraServer/rest/api/*/search" -and
            $GetParameter["jql"] -eq $jqlEscaped
        } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $response
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
            $Method -eq 'Get' -and
            $URI -like "$jiraServer/rest/api/*/filter/*"
        } {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $response
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mocks

        Context "Sanity checking" {
            $command = Get-Command -Name Get-JiraIssue

            defParam $command 'Key'
            defParam $command 'InputObject'
            defParam $command 'Query'
            defParam $command 'Filter'
            defParam $command 'Fields'
            defParam $command 'StartIndex'
            defParam $command 'MaxResults'
            defParam $command 'PageSize'
            defParam $command 'Credential'
        }

        Context "Behavior testing" {

            It "Obtains information about a provided issue in JIRA" {
                { Get-JiraIssue -Key TEST-001 } | Should -Not -Throw

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Method -eq 'Get' -and
                        $URI -like '*/rest/api/*/issue/TEST-001*'
                    }
                    Scope           = 'It'
                    Exactly         = $true
                    Times           = 1
                }
                Assert-MockCalled @assertMockCalledSplat
            }

            It "Uses JQL to search for issues if the -Query parameter is used" {
                { Get-JiraIssue -Query $jql } | Should -Not -Throw

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Method -eq 'Get' -and
                        $URI -like "*/rest/api/*/search" -and
                        $GetParameter["jql"] -eq $jqlEscaped
                    }
                    Scope           = 'It'
                    Exactly         = $true
                    Times           = 1
                }
                Assert-MockCalled @assertMockCalledSplat
            }

            It "Supports the -StartIndex and -MaxResults parameters to page through search results" {
                { Get-JiraIssue -Query $jql -StartIndex 10 -MaxResults 50 } | Should -Not -Throw

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Method -eq 'Get' -and
                        $URI -like "*/rest/api/*/search" -and
                        $GetParameter["jql"] -eq $jqlEscaped -and
                        $PSCmdlet.PagingParameters.Skip -eq 10
                        $PSCmdlet.PagingParameters.First -eq 50
                    }
                    Scope           = 'It'
                    Exactly         = $true
                    Times           = 1
                }
                Assert-MockCalled @assertMockCalledSplat
            }

            It "Returns all issues via looping if -MaxResults is not specified" {
                { Get-JiraIssue -Query $jql -PageSize 25 } | Should -Not -Throw

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Method -eq 'Get' -and
                        $URI -like "*/rest/api/*/search" -and
                        $GetParameter["jql"] -eq $jqlEscaped -and
                        $GetParameter["maxResults"] -eq 25
                    }
                    Scope           = 'It'
                    Exactly         = $true
                    Times           = 1
                }
                Assert-MockCalled @assertMockCalledSplat
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

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Method -eq 'Get' -and
                        $GetParameter["fields"] -eq "*all"
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
                        $GetParameter["fields"] -eq "key"
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
                        $GetParameter["fields"] -eq "-summary"
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
                        $GetParameter["fields"] -eq "key,summary,status"
                    }
                    Scope           = 'It'
                    Exactly         = $true
                    Times           = 4
                }
                Assert-MockCalled @assertMockCalledSplat
            }
        }

        Context "Input testing" {
            It "Accepts an issue key for the -Key parameter" {
                { Get-JiraIssue -Key TEST-001 } | Should -Not -Throw

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Method -eq 'Get' -and
                        $URI -like "*/rest/api/*/issue/TEST-001*"
                    }
                    Scope           = 'It'
                    Exactly         = $true
                    Times           = 1
                }
                Assert-MockCalled @assertMockCalledSplat
            }

            It "Accepts an issue object for the -InputObject parameter" {
                $issue = [PSCustomObject] @{
                    'Key' = 'TEST-001'
                    'ID'  = '12345'
                }
                $issue.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')

                # Should call Get-JiraIssue using the -Key parameter, so our URL should reflect the key we provided
                { Get-JiraIssue -InputObject $Issue } | Should -Not -Throw

                $assertMockCalledSplat = @{
                    CommandName     = 'Invoke-JiraMethod'
                    ModuleName      = 'JiraPS'
                    ParameterFilter = {
                        $Method -eq 'Get' -and
                        $URI -like "*/rest/api/*/issue/TEST-001*"
                    }
                    Scope           = 'It'
                    Exactly         = $true
                    Times           = 1
                }
                Assert-MockCalled @assertMockCalledSplat
            }
        }
    }
}
