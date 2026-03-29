#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
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
                    $i.PSObject.TypeNames.Insert(0, 'JiraPS.Filter')
                    $i | Add-Member -MemberType AliasProperty -Name 'RestURL' -Value 'self'
                    $i
                }
            }

            Mock Get-JiraFilter -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraFilter' 'Id'
                foreach ($i in $Id) {
                    ConvertTo-JiraFilter (ConvertFrom-Json $responseFilter)
                }
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/*/filter/*" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $responseFilter
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Remove-JiraFilter
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'InputObject'; type = 'Object' }
                    @{ parameter = 'Id'; type = 'UInt32[]' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            Context "Filter Deletion" {
                It "deletes a filter based on one or more InputObjects" {
                    { Get-JiraFilter -Id 12844 | Remove-JiraFilter } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter { $Method -eq 'Delete' -and $URI -like '*/rest/api/*/filter/12844' }
                }

                It "deletes a filter based on one or more filter ids" {
                    { Remove-JiraFilter -Id 12844 } | Should -Not -Throw

                    Should -Invoke -CommandName Get-JiraFilter -ModuleName JiraPS -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter { $Method -eq 'Delete' -and $URI -like '*/rest/api/*/filter/12844' }
                }
            }
        }

        Describe "Input Validation" {
            Context "Positive cases" {
                It "Accepts a filter object for the -InputObject parameter" {
                    { Remove-JiraFilter -InputObject (Get-JiraFilter "12345") } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "Accepts a filter object without the -InputObject parameter" {
                    { Remove-JiraFilter (Get-JiraFilter "12345") } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "Accepts multiple filter objects to the -Filter parameter" {
                    { Remove-JiraFilter -InputObject (Get-JiraFilter 12345, 12345) } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -Scope It
                }

                It "Accepts a JiraPS.Filter object via pipeline" {
                    { Get-JiraFilter 12345, 12345 | Remove-JiraFilter } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -Scope It
                }

                It "Accepts an ID of a filter" {
                    { Remove-JiraFilter -Id 12345 } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "Accepts multiple IDs of filters" {
                    { Remove-JiraFilter -Id 12345, 12345 } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -Scope It
                }

                It "Accepts multiple IDs of filters over the pipeline" {
                    { 12345, 12345 | Remove-JiraFilter } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -Scope It
                }
            }

            Context "Negative cases" {
                It "fails if a negative number is passed as ID" {
                    { Remove-JiraFilter -Id -1 } | Should -Throw
                }

                It "fails if something other than [JiraPS.Filter] is provided" {
                    { Get-Date | Remove-JiraFilter -ErrorAction Stop } | Should -Throw
                    { Remove-JiraFilter "12345" -ErrorAction Stop } | Should -Throw
                }
            }
        }
    }
}
