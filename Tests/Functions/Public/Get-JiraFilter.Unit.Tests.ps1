#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Get-JiraFilter" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

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

            $script:responseFilterCollection = @"
[
    {
        "self": "$jiraServer/rest/api/2/filter/13844",
        "id": "13844",
        "name": "Filter 1",
        "jql": "project = 10240 AND issuetype = 1 ORDER BY key DESC",
        "favourite": true
    },
    {
        "self": "$jiraServer/rest/api/2/filter/14844",
        "id": "14844",
        "name": "Filter 2",
        "jql": "project = 10240 AND issuetype = 1 ORDER BY key DESC",
        "favourite": true
    },
    {
        "self": "$jiraServer/rest/api/2/filter/15844",
        "id": "15844",
        "name": "Filter 3",
        "jql": "project = 10240 AND issuetype = 1 ORDER BY key DESC",
        "favourite": true
    }
]
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock ConvertTo-JiraFilter -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraFilter'
                foreach ($i in $InputObject) {
                    $i.PSObject.TypeNames.Insert(0, 'JiraPS.Filter')
                    $i
                }
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/filter/12345" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $responseFilter
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/filter/67890" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $responseFilter
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/filter/favourite" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $responseFilterCollection
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/*/filter/*" } {
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
            Context "Parameter Types" {
                # TODO: Add parameter type validation tests
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            Context "Behavior testing" {
                It "Queries JIRA for a filter with a given ID" {
                    { Get-JiraFilter -Id 12345 } | Should -Not -Throw
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like '*/rest/api/*/filter/12345' }
                }

                It "Uses ConvertTo-JiraFilter to output a Filter object if JIRA returns data" {
                    Mock Invoke-JiraMethod -ModuleName JiraPS { $true }
                    Mock ConvertTo-JiraFilter -ModuleName JiraPS {}
                    { Get-JiraFilter -Id 12345 } | Should -Not -Throw
                    Should -Invoke ConvertTo-JiraFilter -ModuleName JiraPS
                }

                It "Finds all favorite filters of the user" {
                    { Get-JiraFilter -Favorite } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like '*/rest/api/*/filter/favourite' }
                }
            }

            Context "Input testing" {
                BeforeAll {
                    $script:sampleFilter = ConvertTo-JiraFilter (ConvertFrom-Json $responseFilter)
                }

                It "Accepts a filter ID for the -Filter parameter" {
                    { Get-JiraFilter -Id "12345" } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "Accepts a filter ID without the -Filter parameter" {
                    { Get-JiraFilter "12345" } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "Accepts multiple filter IDs to the -Filter parameter" {
                    { Get-JiraFilter -Id '12345', '67890' } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like '*/rest/api/*/filter/12345' }
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like '*/rest/api/*/filter/67890' }
                }

                It "Accepts a JiraPS.Filter object to the InputObject parameter" {
                    { Get-JiraFilter -InputObject $sampleFilter } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like '*rest/api/*/filter/12844' }
                }

                It "Accepts a JiraPS.Filter object via pipeline" {
                    { $sampleFilter | Get-JiraFilter } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter { $Method -eq 'Get' -and $URI -like '*rest/api/*/filter/12844' }
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
