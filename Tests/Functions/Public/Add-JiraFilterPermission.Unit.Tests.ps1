#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $moduleToTest -Force -ErrorAction Stop
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
            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock ConvertTo-JiraFilter -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraFilter'
                $i = New-Object -TypeName PSCustomObject
                $i.PSObject.TypeNames.Insert(0, 'JiraPS.Filter')
                $i
            }

            Mock ConvertTo-JiraFilterPermission -ModuleName JiraPS {
                Write-MockDebugInfo 'ConvertTo-JiraFilterPermission'
                $i = (ConvertFrom-Json $permissionJSON)
                $i.PSObject.TypeNames.Insert(0, 'JiraPS.FilterPermission')
                $i
            }

            Mock Get-JiraFilter -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraFilter' 'Id'
                foreach ($_id in $Id) {
                    $object = New-Object -TypeName PSCustomObject -Property @{
                        id      = $_id
                        RestUrl = "$jiraServer/rest/api/2/filter/$_id"
                    }
                    $object.PSObject.TypeNames.Insert(0, 'JiraPS.Filter')
                    $object
                }
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Post' -and $URI -like "$jiraServer/rest/api/*/filter/*/permission"
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
                ConvertFrom-Json $permissionJSON
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod: $Method $URI"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name 'Add-JiraFilterPermission'
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "Filter"; type = "JiraPS.Filter" }
                    @{ parameter = "Id"; type = "UInt32[]" }
                    @{ parameter = "Type"; type = "String" }
                    @{ parameter = "Value"; type = "String" }
                    @{ parameter = "Credential"; type = "System.Management.Automation.PSCredential" }
                ) {
                    $command | Should -HaveParameter $parameter

                    #ToDo:CustomClass
                    # This test is currently broken - can't validate type this way
                    # can't use -Type with Should -HaveParameter as long we are using `PSObject.TypeNames.Insert(0, 'JiraPS.Filter')`
                    (Get-Member -InputObject $command.Parameters.Item($parameter)).Attributes | Should -Contain $typeName
                }
            }

            Context "Default Values" {
                It "parameter '<parameter>' has a default value of '<defaultValue>'" -TestCases @(
                    @{ parameter = "Credential"; defaultValue = "[System.Management.Automation.PSCredential]::Empty" }
                ) {
                    $command | Should -HaveParameter $parameter -DefaultValue $defaultValue
                }
            }

            Context "Mandatory Parameters" {
                It "parameter '<parameter>' is mandatory" -TestCases @(
                    @{ parameter = "Filter" }
                    @{ parameter = "Id" }
                    @{ parameter = "Type" }
                ) {
                    $command | Should -HaveParameter $parameter -Mandatory
                }
            }
        }

        Describe "Behavior" {
            Context "Filter Object Input" {
                It "Adds share permission to Filter Object" {
                    $filter = Get-JiraFilter -Id 12844
                    {
                        Add-JiraFilterPermission -Filter $filter -Type "Global"
                    } | Should -Not -Throw

                    Should -Invoke 'Invoke-JiraMethod' -ModuleName 'JiraPS' -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like '*/rest/api/*/filter/12844/permission'
                    }

                    Should -Invoke 'ConvertTo-JiraFilter' -ModuleName 'JiraPS' -Exactly -Times 1 -Scope It
                }
            }

            Context "Filter ID Input" {
                It "Adds share permission to FilterId" {
                    {
                        Add-JiraFilterPermission -Id 12844 -Type "Global"
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like '*/rest/api/*/filter/12844/permission'
                    }

                    Should -Invoke -CommandName ConvertTo-JiraFilter -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Negative Cases" {
                It "rejects invalid type '<description>' with meaningful error" -TestCases @(
                    @{ invalidType = 1; description = "integer" }
                    @{ invalidType = "lorem"; description = "string" }
                    @{ invalidType = (Get-Date); description = "DateTime object" }
                ) {
                    { Add-JiraFilterPermission -Filter $invalidType -Type "Global" } |
                        Should -Throw -ExpectedMessage "*Filter*"
                }
            }

            Context "Type Validation - Positive Cases" {
                It "accepts JiraPS.Filter objects" {
                    { Add-JiraFilterPermission -Filter (Get-JiraFilter -Id 1) -Type "Global" } | Should -Not -Throw
                }

                It "can find a filter by it's Id" {
                    { Add-JiraFilterPermission -Id 1 -Type "Global" } | Should -Not -Throw

                    Should -Invoke -CommandName Get-JiraFilter -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }
            }

            Context "Pipeline Support" {
                It "allows a JiraPS.Filter to be passed over the pipeline" {
                    { Get-JiraFilter -Id 1 | Add-JiraFilterPermission -Type "Global" } | Should -Not -Throw
                }

                It "allows for the filter's Id to be passed over the pipeline" {
                    { 1, 2 | Add-JiraFilterPermission -Type "Global" } | Should -Not -Throw

                    Should -Invoke -CommandName Get-JiraFilter -ModuleName JiraPS -Exactly -Times 2 -Scope It
                }
            }

            Context "Multiple Items" {
                It "can process multiple Filters" {
                    $filters = 1..5 | ForEach-Object { Get-JiraFilter -Id 1 }
                    $filters | Should -HaveCount 5

                    { Add-JiraFilterPermission -Filter $filters -Type "Global" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 5 -Scope It
                }

                It "can process mutiple FilterIds" {
                    { Add-JiraFilterPermission -Id 1, 2, 3, 4, 5 -Type "Global" } | Should -Not -Throw

                    Should -Invoke -CommandName Get-JiraFilter -ModuleName JiraPS -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 5 -Scope It
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

            Context "Permission Types - Positive Cases" {
                It "accepts valid permission type '<validType>'" -TestCases @(
                    @{ validType = "Global" }
                    @{ validType = "Group" }
                    @{ validType = "Project" }
                    @{ validType = "ProjectRole" }
                    @{ validType = "Authenticated" }
                ) {
                    { Add-JiraFilterPermission -Id 1 -Type $validType } | Should -Not -Throw
                }

                It "does not validate -Value" {
                    { Add-JiraFilterPermission -Id 1 -Type "Global" -Value "invalid" } | Should -Not -Throw
                    { Add-JiraFilterPermission -Id 1 -Type "Group" -Value "not a group" } | Should -Not -Throw
                    { Add-JiraFilterPermission -Id 1 -Type "Project" -Value "not a project" } | Should -Not -Throw
                    { Add-JiraFilterPermission -Id 1 -Type "ProjectRole" -Value "not a Role" } | Should -Not -Throw
                    { Add-JiraFilterPermission -Id 1 -Type "Authenticated" -Value "invalid" } | Should -Not -Throw
                }
            }

            Context "Request Body Construction" {
                It "constructs a valid request Body for type 'Global'" {
                    { Add-JiraFilterPermission -Id 12844 -Type "Global" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like '*/rest/api/*/filter/12844/permission' -and
                        $Body -match '"type":\s*"global"' -and
                        $Body -notmatch ','
                    }
                }

                It "constructs a valid request Body for type 'Authenticated'" {
                    { Add-JiraFilterPermission -Id 12844 -Type "Authenticated" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like '*/rest/api/*/filter/12844/permission' -and
                        $Body -match '"type":\s*"authenticated"' -and
                        $Body -notmatch ","
                    }
                }

                It "constructs a valid request Body for type 'Group'" {
                    { Add-JiraFilterPermission -Id 12844 -Type "Group" -Value "administrators" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like '*/rest/api/*/filter/12844/permission' -and
                        $Body -match '"type":\s*"group"' -and
                        $Body -match '"groupname":\s*"administrators"'
                    }
                }

                It "constructs a valid request Body for type 'Project'" {
                    { Add-JiraFilterPermission -Id 12844 -Type "Project" -Value "11822" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Post' -and
                        $URI -like '*/rest/api/*/filter/12844/permission' -and
                        $Body -match '"type":\s*"project"' -and
                        $Body -match '"projectId":\s*"11822"'
                    }
                }

                It "constructs a valid request Body for type 'ProjectRole'" {
                    { Add-JiraFilterPermission -Id 12844 -Type "ProjectRole" -Value "11822" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
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
