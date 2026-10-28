#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Nonsecret unit-test credential fixture.')]
param()

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Add-JiraFilterPermission" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:jiraServer = "https://jira.example.com"

            $script:permissionJSON = @"
[
    {
        "id": 10000,
        "type": "global"
    },
    {
        "id": 10010,
        "type": "project",
        "project": {
        "self": "$jiraServer/jira/rest/api/2/project/EX",
        "id": "10000",
        "key": "EX",
        "name": "Example",
        "avatarUrls": {
            "48x48": "$jiraServer/jira/secure/projectavatar?size=large&pid=10000",
            "24x24": "$jiraServer/jira/secure/projectavatar?size=small&pid=10000",
            "16x16": "$jiraServer/jira/secure/projectavatar?size=xsmall&pid=10000",
            "32x32": "$jiraServer/jira/secure/projectavatar?size=medium&pid=10000"
        },
        "projectCategory": {
            "self": "$jiraServer/jira/rest/api/2/projectCategory/10000",
            "id": "10000",
            "name": "FIRST",
            "description": "First Project Category"
        },
        "simplified": false
        }
    },
    {
        "id": 10010,
        "type": "project",
        "project": {
        "self": "$jiraServer/jira/rest/api/2/project/MKY",
        "id": "10002",
        "key": "MKY",
        "name": "Example",
        "avatarUrls": {
            "48x48": "$jiraServer/jira/secure/projectavatar?size=large&pid=10002",
            "24x24": "$jiraServer/jira/secure/projectavatar?size=small&pid=10002",
            "16x16": "$jiraServer/jira/secure/projectavatar?size=xsmall&pid=10002",
            "32x32": "$jiraServer/jira/secure/projectavatar?size=medium&pid=10002"
        },
        "projectCategory": {
            "self": "$jiraServer/jira/rest/api/2/projectCategory/10000",
            "id": "10000",
            "name": "FIRST",
            "description": "First Project Category"
        },
        "simplified": false
        },
        "role": {
        "self": "$jiraServer/jira/rest/api/2/project/MKY/role/10360",
        "name": "Developers",
        "id": 10360,
        "description": "A project role that represents developers in a project",
        "actors": [
            {
            "id": 10240,
            "displayName": "jira-developers",
            "type": "atlassian-group-role-actor",
            "name": "jira-developers"
            },
            {
            "id": 10241,
            "displayName": "Fred F. User",
            "type": "atlassian-user-role-actor",
            "name": "fred"
            }
        ]
        }
    },
    {
        "id": 10010,
        "type": "group",
        "group": {
        "name": "jira-administrators",
        "self": "$jiraServer/jira/rest/api/2/group?groupname=jira-administrators"
        }
    }
]
"@
            #endregion Definitions

            #region Mocks
            Mock ConvertTo-JiraFilter -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraFilter'
                $i = New-Object -TypeName PSCustomObject
                $i.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.Filter')
                $i
            }

            Mock ConvertTo-JiraFilterPermission -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraFilterPermission'
                $i = (ConvertFrom-Json $permissionJSON)
                $i.PSObject.TypeNames.Insert(0, 'JiraPS.FilterPermission')
                $i
            }

            Mock Get-JiraFilterOperation -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraFilter' 'InputObject'
                foreach ($item in $Filter) {
                    [AtlassianPS.JiraPS.Filter]@{
                        Id      = $item.Id
                        RestUrl = "$jiraServer/rest/api/2/filter/$($item.Id)"
                    }
                }
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Post' -and $URI -like "$jiraServer/rest/api/*/filter/*/permission"
            } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri', 'Body'
                ConvertFrom-Json $permissionJSON
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraRequest: $Method $URI"
            }
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "Typed references and aliases" {
                It "accepts arrays through '<parameter>'" -TestCases @(
                    @{ parameter = 'Filter' }
                    @{ parameter = 'Id' }
                ) {
                    param($parameter)
                    $arguments = @{ $parameter = @('12345', '67890') }
                    Add-JiraFilterPermission @arguments -Type Global -Confirm:$false

                    Should -Invoke Invoke-JiraRequest -Exactly -Times 2
                    Should -Invoke Invoke-JiraRequest -Exactly -Times 1 -ParameterFilter { $URI -like '*/filter/12345/permission' }
                    Should -Invoke Invoke-JiraRequest -Exactly -Times 1 -ParameterFilter { $URI -like '*/filter/67890/permission' }
                }

                It "accepts numeric strings from the pipeline" {
                    '12345', '67890' | Add-JiraFilterPermission -Type Global -Confirm:$false

                    Should -Invoke Invoke-JiraRequest -Exactly -Times 2
                    Should -Invoke Invoke-JiraRequest -Exactly -Times 1 -ParameterFilter { $URI -like '*/filter/12345/permission' }
                    Should -Invoke Invoke-JiraRequest -Exactly -Times 1 -ParameterFilter { $URI -like '*/filter/67890/permission' }
                }

                It "accepts a complete typed filter from the pipeline" {
                    $filter = [AtlassianPS.JiraPS.Filter]@{
                        Id      = '12345'
                        Name    = 'Test filter'
                        RestUrl = "$jiraServer/rest/api/2/filter/12345"
                    }
                    $filter | Add-JiraFilterPermission -Type Global -Confirm:$false

                    Should -Invoke Invoke-JiraRequest -Exactly -Times 1
                }
            }

            Context "Filter ID Input" {

                It "does not add permissions under WhatIf" {
                    Add-JiraFilterPermission -Id 12844 -Type Global -WhatIf

                    Should -Invoke Invoke-JiraRequest -Exactly -Times 0
                }

            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Negative Cases" {
                It "rejects invalid type '<description>' with meaningful error" -TestCases @(
                    @{ invalidType = "lorem"; description = "string" }
                    @{ invalidType = (Get-Date); description = "DateTime object" }
                ) {
                    { Add-JiraFilterPermission -Filter $invalidType -Type "Global" } |
                        Should -Throw -ExpectedMessage "*Filter*"
                }
            }

            Context "Permission Types - Negative Cases" {
                It "rejects invalid permission type '<invalidType>' with ValidateSet error" -TestCases @(
                    @{ invalidType = "lorem" }
                    @{ invalidType = "Invalid" }
                ) {
                    { Add-JiraFilterPermission -Id 1 -Type $invalidType } |
                        Should -Throw -ExpectedMessage "*'Type'*"
                }
            }

            Context "Request Body Construction" {
                It "constructs a valid request Body for type 'Global'" {
                    { Add-JiraFilterPermission -Id 12844 -Type "Global" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like '*/rest/api/*/filter/12844/permission' -and
                        $Body -match '"type":\s*"global"' -and
                        $Body -notmatch ','
                    }
                }

                It "constructs a valid request Body for type 'Authenticated'" {
                    { Add-JiraFilterPermission -Id 12844 -Type "Authenticated" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like '*/rest/api/*/filter/12844/permission' -and
                        $Body -match '"type":\s*"authenticated"' -and
                        $Body -notmatch ","
                    }
                }

                It "constructs a valid request Body for type 'Group'" {
                    { Add-JiraFilterPermission -Id 12844 -Type "Group" -Value "administrators" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like '*/rest/api/*/filter/12844/permission' -and
                        $Body -match '"type":\s*"group"' -and
                        $Body -match '"groupname":\s*"administrators"'
                    }
                }

                It "constructs a valid request Body for type 'Project'" {
                    { Add-JiraFilterPermission -Id 12844 -Type "Project" -Value "11822" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like '*/rest/api/*/filter/12844/permission' -and
                        $Body -match '"type":\s*"project"' -and
                        $Body -match '"projectId":\s*"11822"'
                    }
                }

                It "constructs a valid request Body for type 'ProjectRole'" {
                    { Add-JiraFilterPermission -Id 12844 -Type "ProjectRole" -Value "11822" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like '*/rest/api/*/filter/12844/permission' -and
                        $Body -match '"type":\s*"projectRole"' -and
                        $Body -match '"projectRoleId":\s*"11822"'
                    }
                }
            }
        }
    }
}
