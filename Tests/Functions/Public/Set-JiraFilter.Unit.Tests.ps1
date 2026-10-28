#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Set-JiraFilter" -Tag 'Unit' {

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
            Mock Get-JiraFilterOperation -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraFilter' 'InputObject'
                foreach ($i in $Filter) {
                    ConvertTo-JiraFilter (ConvertFrom-Json $responseFilter)
                }
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/*/filter/*" } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri', 'Body'
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
                $script:command = Get-Command -Name Set-JiraFilter
            }

            Context "Parameter Types" {

                It "has an alias 'Favourite' for parameter 'Favorite'" {
                    $command.Parameters.Item('Favorite').Aliases | Should -Contain 'Favourite'
                }
            }

        }

        Describe "Behavior" {
            Context "Filter Update" {
                It "Invokes the Jira API to update a filter" {
                    {
                        $newData = @{
                            Name        = "newName"
                            Description = "newDescription"
                            JQL         = "newJQL"
                            Favorite    = $true
                        }
                        Get-JiraFilter -Id 12844 | Set-JiraFilter @newData
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/filter/12844' -and
                        $Body -match "`"name`":\s*`"newName`"" -and
                        $Body -match "`"description`":\s*`"newDescription`"" -and
                        $Body -match "`"jql`":\s*`"newJQL`"" -and
                        $Body -match "`"favourite`":\s*true"
                    }
                }

                It "Can set the Description to Empty" {
                    {
                        $newData = @{
                            Description = ""
                        }
                        Get-JiraFilter -Id 12844 | Set-JiraFilter @newData
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/filter/12844' -and
                        $Body -match "`"description`":\s*`"`""
                    }
                }

                It "Skips the filter if no value was changed" {
                    { Get-JiraFilter -Id 12844 | Set-JiraFilter } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 0
                }
            }
        }

        Describe "Input Validation" {
            Context "Positive cases" {
                It "sends only the supplied '<parameter>' field" -TestCases @(
                    @{ parameter = 'Name'; field = 'name'; value = 'New name' }
                    @{ parameter = 'Description'; field = 'description'; value = 'New description' }
                    @{ parameter = 'JQL'; field = 'jql'; value = 'project = TEST' }
                    @{ parameter = 'Favorite'; field = 'favourite'; value = $false }
                ) {
                    param($parameter, $field, $value)
                    $arguments = @{ $parameter = $value }
                    Set-JiraFilter -Filter (Get-JiraFilter '12844') @arguments -Confirm:$false

                    Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $payload = ConvertFrom-Json -InputObject $Body
                        $Method -eq 'Put' -and $URI -like '*/rest/api/*/filter/12844' -and
                        @($payload.PSObject.Properties).Count -eq 1 -and
                        $payload.PSObject.Properties.Name -eq $field -and $payload.$field -eq $value
                    }
                }

                It "accepts a filter object for the -Filter parameter" {
                    { Set-JiraFilter -Filter (Get-JiraFilter "12345") -Name "test" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1
                }

                It "accepts a filter object without the -Filter parameter" {
                    { Set-JiraFilter (Get-JiraFilter "12345") -Name "test" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1
                }

                It "accepts a AtlassianPS.JiraPS.Filter object via pipeline" {
                    { Get-JiraFilter 12345, 12345 | Set-JiraFilter -Name "test" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 2
                }
            }

            Context "Negative cases" {
                It "fails with multiple filter objects to the -Filter parameter" {
                    { Set-JiraFilter -Filter (Get-JiraFilter 12345, 12345) -Name "test" } | Should -Throw -ExpectedMessage "*Filter*"
                }

                It "fails if something other than [AtlassianPS.JiraPS.Filter] is provided to InputObject" {
                    { Get-Date | Set-JiraFilter -ErrorAction Stop } | Should -Throw -ExpectedMessage "*Filter*"
                }
            }
        }
    }
}
