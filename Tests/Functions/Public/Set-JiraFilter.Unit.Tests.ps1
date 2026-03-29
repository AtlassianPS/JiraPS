#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
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

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' -and $URI -like "$jiraServer/rest/api/*/filter/*" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
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
                $script:command = Get-Command -Name Set-JiraFilter
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'InputObject'; type = 'Object' }
                    @{ parameter = 'Name'; type = 'String' }
                    @{ parameter = 'Description'; type = 'String' }
                    @{ parameter = 'JQL'; type = 'String' }
                    @{ parameter = 'Favorite'; type = 'Boolean' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter -Type $type
                }

                It "has an alias 'Favourite' for parameter 'Favorite'" {
                    $command.Parameters.Item('Favorite').Aliases | Should -Contain 'Favourite'
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
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

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
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

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/filter/12844' -and
                        $Body -match "`"description`":\s*`"`""
                    }
                }

                It "Skips the filter if no value was changed" {
                    { Get-JiraFilter -Id 12844 | Set-JiraFilter } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 0 -Scope It
                }
            }
        }

        Describe "Input Validation" {
            Context "Positive cases" {
                It "accepts a filter object for the -InputObject parameter" {
                    { Set-JiraFilter -InputObject (Get-JiraFilter "12345") -Name "test" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "accepts a filter object without the -InputObject parameter" {
                    { Set-JiraFilter (Get-JiraFilter "12345") -Name "test" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "accepts a JiraPS.Filter object via pipeline" {
                    { Get-JiraFilter 12345, 12345 | Set-JiraFilter -Name "test" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -Scope It
                }

                It "accepts -InputObject" {
                    {
                        $parameter = @{
                            InputObject = Get-JiraFilter "12345"
                        }
                        Set-JiraFilter @parameter
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 0 -Scope It
                }

                It "accepts -InputObject and -Name" {
                    {
                        $parameter = @{
                            InputObject = Get-JiraFilter "12345"
                            Name        = "newName"
                        }
                        Set-JiraFilter @parameter
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "accepts -InputObject and -Description" {
                    {
                        $parameter = @{
                            InputObject = Get-JiraFilter "12345"
                            Description = "newDescription"
                        }
                        Set-JiraFilter @parameter
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "accepts -InputObject and -JQL" {
                    {
                        $parameter = @{
                            InputObject = Get-JiraFilter "12345"
                            JQL         = "newJQL"
                        }
                        Set-JiraFilter @parameter
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "accepts -InputObject and -Favorite" {
                    {
                        $parameter = @{
                            InputObject = Get-JiraFilter "12345"
                            Favorite    = $true
                        }
                        Set-JiraFilter @parameter
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "accepts -InputObject and -Name and -Description" {
                    {
                        $parameter = @{
                            InputObject = Get-JiraFilter "12345"
                            Name        = "newName"
                            Description = "newDescription"
                        }
                        Set-JiraFilter @parameter
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "accepts -InputObject and -Name and -JQL" {
                    {
                        $parameter = @{
                            InputObject = Get-JiraFilter "12345"
                            Name        = "newName"
                            JQL         = "newJQL"
                        }
                        Set-JiraFilter @parameter
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "accepts -InputObject and -Name and -Favorite" {
                    {
                        $parameter = @{
                            InputObject = Get-JiraFilter "12345"
                            Name        = "newName"
                            Favorite    = $true
                        }
                        Set-JiraFilter @parameter
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "accepts -InputObject and -Name and -Description and -JQL" {
                    {
                        $parameter = @{
                            InputObject = Get-JiraFilter "12345"
                            Name        = "newName"
                            Description = "newDescription"
                            JQL         = "newJQL"
                        }
                        Set-JiraFilter @parameter
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "accepts -InputObject and -Name and -Description and -Favorite" {
                    {
                        $parameter = @{
                            InputObject = Get-JiraFilter "12345"
                            Name        = "newName"
                            Description = "newDescription"
                            Favorite    = $true
                        }
                        Set-JiraFilter @parameter
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "accepts -InputObject and -Name and -Description and -JQL and -Favorite" {
                    {
                        $parameter = @{
                            InputObject = Get-JiraFilter "12345"
                            Name        = "newName"
                            Description = "newDescription"
                            JQL         = "newJQL"
                            Favorite    = $true
                        }
                        Set-JiraFilter @parameter
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }
            }

            Context "Negative cases" {
                It "fails with multiple filter objects to the -Filter parameter" {
                    { Set-JiraFilter -InputObject (Get-JiraFilter 12345, 12345) -Name "test" } | Should -Throw
                }

                It "fails if something other than [JiraPS.Filter] is provided to InputObject" {
                    { "12345" | Set-JiraFilter -ErrorAction Stop } | Should -Throw
                    { Set-JiraFilter "12345" -ErrorAction Stop } | Should -Throw
                }
            }
        }
    }
}
