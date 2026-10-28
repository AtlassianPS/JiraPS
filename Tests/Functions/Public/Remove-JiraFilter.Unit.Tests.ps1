#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Nonsecret unit-test credential fixture.')]
param()

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Remove-JiraFilter" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = "https://jira.example.com"

            $script:responseFilter = @"
{
    "self": "$jiraServer/rest/api/2/filter/12844",
    "id": "12844",
    "name": "All JIRA Bugs",
    "owner": {
        "self": "$jiraServer/rest/api/2/user?username=scott@atlassian.com",
        "key": "scott@atlassian.com",
        "name": "scott@atlassian.com",
        "avatarUrls": {
            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10612",
            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10612",
            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10612",
            "48x48": "$jiraServer/secure/useravatar?avatarId=10612"
        },
        "displayName": "Scott Farquhar [Atlassian]",
        "active": true
    },
    "jql": "project = 10240 AND issuetype = 1 ORDER BY key DESC",
    "viewUrl": "$jiraServer/secure/IssueNavigator.jspa?mode=hide&requestId=12844",
    "searchUrl": "$jiraServer/rest/api/2/search?jql=project+%3D+10240+AND+issuetype+%3D+1+ORDER+BY+key+DESC",
    "favourite": false,
    "sharePermissions": [
        {
            "id": 10049,
            "type": "global"
        }
    ],
    "sharedUsers": {
        "size": 0,
        "items": [],
        "max-results": 1000,
        "start-index": 0,
        "end-index": 0
    },
    "subscriptions": {
        "size": 0,
        "items": [],
        "max-results": 1000,
        "start-index": 0,
        "end-index": 0
    }
}
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock ConvertTo-JiraFilter -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraFilter' 'InputObject'
                foreach ($i in $InputObject) {
                    $i.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.Filter')
                    $i | Add-Member -MemberType AliasProperty -Name 'RestURL' -Value 'self'
                    $i
                }
            }

            Mock Get-JiraFilterOperation -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraFilter' 'InputObject'
                foreach ($i in $InputObject) {
                    ConvertTo-JiraFilter (ConvertFrom-Json $responseFilter)
                }
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/*/filter/*" } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                ConvertFrom-Json $responseFilter
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraRequest"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Remove-JiraFilter
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'InputObject'; type = 'AtlassianPS.JiraPS.Filter[]' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }

            Context "Aliases" {
                It "preserves the ID parameter spellings" {
                    $command.Parameters.InputObject.Aliases | Should -Contain 'Id'
                    $command.Parameters.InputObject.Aliases | Should -Contain 'FilterId'
                }
            }

            Context "Parameter Sets" {
                It "uses one parameter set for filter objects and IDs" {
                    $command.ParameterSets.Count | Should -Be 1
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            Context "Filter Deletion" {
                It "supports the '<parameter>' spelling with numeric strings" -TestCases @(
                    @{ parameter = 'InputObject' }
                    @{ parameter = 'Id' }
                    @{ parameter = 'FilterId' }
                ) {
                    param($parameter)
                    $arguments = @{ $parameter = '12844'; Confirm = $false }
                    Remove-JiraFilter @arguments

                    Should -Invoke Get-JiraFilterOperation -Exactly -Times 1 -ParameterFilter { $InputObject.Id -eq 12844 }
                    Should -Invoke Invoke-JiraRequest -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'DELETE' -and $URI -like '*/filter/12844'
                    }
                }

                It "forwards credentials when resolving filter IDs and deleting filters" {
                    $credential = [PSCredential]::new('filter-owner', (ConvertTo-SecureString 'fixture-password' -AsPlainText -Force))
                    Remove-JiraFilter -Id 12844 -Credential $credential -Confirm:$false

                    Should -Invoke Get-JiraFilterOperation -Exactly -Times 1 -ParameterFilter {
                        $RequestContext.Username -eq 'filter-owner' -and $ErrorAction -eq 'Stop'
                    }
                    Should -Invoke Invoke-JiraRequest -Exactly -Times 1 -ParameterFilter { $RequestContext.Username -eq 'filter-owner' }
                }

                It "does not delete any filters when a later array lookup fails through '<parameter>'" -TestCases @(
                    @{ parameter = 'InputObject' }
                    @{ parameter = 'Id' }
                ) {
                    param($parameter)
                    Mock Get-JiraFilterOperation -ModuleName JiraPS -ParameterFilter { $InputObject.Id -eq 67890 } {
                        throw 'Filter 67890 is not accessible.'
                    }
                    $arguments = @{ $parameter = @(12844, 67890); Confirm = $false }

                    { Remove-JiraFilter @arguments } | Should -Throw -ExpectedMessage '*Filter 67890 is not accessible*'

                    Should -Invoke Get-JiraFilterOperation -Exactly -Times 2
                    Should -Invoke Invoke-JiraRequest -Exactly -Times 0 -ParameterFilter { $Method -eq 'DELETE' }
                }

                It "skips filter deletion under WhatIf" {
                    Remove-JiraFilter -Id 12844 -WhatIf

                    Should -Invoke Invoke-JiraRequest -Exactly -Times 0
                }

                It "uses a complete typed filter without looking it up" {
                    $filter = [AtlassianPS.JiraPS.Filter]@{
                        Id      = '12844'
                        Name    = 'All JIRA Bugs'
                        RestUrl = "$jiraServer/rest/api/2/filter/12844"
                    }
                    $filter | Remove-JiraFilter -Confirm:$false

                    Should -Invoke Get-JiraFilterOperation -Exactly -Times 0
                    Should -Invoke Invoke-JiraRequest -Exactly -Times 1
                }

                It "deletes a filter based on one or more InputObjects" {
                    { Get-JiraFilter -Id 12844 | Remove-JiraFilter } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter { $Method -eq 'Delete' -and $URI -like '*/rest/api/*/filter/12844' }
                }

                It "deletes a filter based on one or more filter ids" {
                    { Remove-JiraFilter -Id 12844 } | Should -Not -Throw

                    Should -Invoke -CommandName Get-JiraFilterOperation -ModuleName JiraPS -Exactly -Times 1
                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter { $Method -eq 'Delete' -and $URI -like '*/rest/api/*/filter/12844' }
                }
            }
        }

        Describe "Input Validation" {
            Context "Positive cases" {
                It "Accepts a filter object for the -InputObject parameter" {
                    { Remove-JiraFilter -InputObject (Get-JiraFilter "12345") } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1
                }

                It "Accepts a filter object without the -InputObject parameter" {
                    { Remove-JiraFilter (Get-JiraFilter "12345") } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1
                }

                It "Accepts multiple filter objects to the -Filter parameter" {
                    { Remove-JiraFilter -InputObject (Get-JiraFilter 12345, 12345) } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 2
                }

                It "Accepts a AtlassianPS.JiraPS.Filter object via pipeline" {
                    { Get-JiraFilter 12345, 12345 | Remove-JiraFilter } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 2
                }

                It "Accepts an ID of a filter" {
                    { Remove-JiraFilter -Id 12345 } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1
                }

                It "Accepts multiple IDs of filters" {
                    { Remove-JiraFilter -Id 12345, 12345 } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 2
                }

                It "Accepts multiple IDs of filters over the pipeline" {
                    { 12345, 12345 | Remove-JiraFilter } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 2
                }
            }

            Context "Negative cases" {
                It "fails if a negative number is passed as ID" {
                    { Remove-JiraFilter -Id -1 } | Should -Throw -ExpectedMessage "*positive numeric ID*"
                }

                It "fails if something other than [AtlassianPS.JiraPS.Filter] is provided" {
                    { Get-Date | Remove-JiraFilter -ErrorAction Stop } | Should -Throw -ExpectedMessage "*Filter*"
                }
            }
        }
    }
}
