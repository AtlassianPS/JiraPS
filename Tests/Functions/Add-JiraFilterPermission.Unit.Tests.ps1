#requires -modules BuildHelpers
#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "4.4.0" }

Describe 'Add-JiraFilterPermission' -Tag 'Unit' {

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

        #region Definitions
        $jiraServer = "https://jira.example.com"

        $permissionJSON = @"
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
            $jiraServer
        }

        Mock ConvertTo-JiraFilter -ModuleName JiraPS {
            $i = New-Object -TypeName PSCustomObject
            $i.PSObject.TypeNames.Insert(0, 'JiraPS.Filter')
            $i
        }

        Mock ConvertTo-JiraFilterPermission -ModuleName JiraPS {
            $i = (ConvertFrom-Json $permissionJSON)
            $i.PSObject.TypeNames.Insert(0, 'JiraPS.FilterPermission')
            $i
        }

        Mock Get-JiraFilter -ModuleName JiraPS {
            foreach ($_id in $Id) {
                $object = New-Object -TypeName PSCustomObject -Property @{
                id = $_id
                RestUrl = "$jiraServer/rest/api/latest/filter/$_id"
            }
            $object.PSObject.TypeNames.Insert(0, 'JiraPS.Filter')
            $object
        }
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Post' -and $URI -like "$jiraServer/rest/api/*/filter/*/permission"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
            ConvertFrom-Json $permissionJSON
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mocks

        Context "Sanity checking" {
            $command = Get-Command -Name Add-JiraFilterPermission

            defParam $command 'Filter'
            defParam $command 'Id'
            defParam $command 'Type'
            defParam $command 'Value'
            defParam $command 'Credential'
        }

        Context "Behavior testing" {
            It "Adds share permission to Filter Object" {
                {
                    Add-JiraFilterPermission -Filter (Get-JiraFilter -Id 12844) -Type "Global"
                } | Should Not Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'Post' -and
                    $URI -like '*/rest/api/*/filter/12844/permission'
                }

                Assert-MockCalled -CommandName ConvertTo-JiraFilter -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "Adds share permission to FilterId" {
                {
                    Add-JiraFilterPermission -Id 12844 -Type "Global"
                } | Should Not Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'Post' -and
                    $URI -like '*/rest/api/*/filter/12844/permission'
                }

                Assert-MockCalled -CommandName ConvertTo-JiraFilter -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }
        }

        Context "Input testing" {
            It "requires -Filter to be a JiraPS.Filter" {
                { Add-JiraFilterPermission -Filter 1 -Type "Global" } | Should -Throw
                { Add-JiraFilterPermission -Filter "lorem" -Type "Global" } | Should -Throw
                { Add-JiraFilterPermission -Filter (Get-Date) -Type "Global" } | Should -Throw

                { Add-JiraFilterPermission -Filter (Get-JiraFilter -Id 1) -Type "Global" } | Should -Not -Throw
            }

            It "allows a JiraPS.Filter to be passed over the pipeline" {
                { Get-JiraFilter -Id 1 | Add-JiraFilterPermission -Type "Global" } | Should -Not -Throw
            }

            It "can process multiple Filters" {
                $filters = 1..5 | ForEach-Object { Get-JiraFilter -Id 1 }
                $filters.Count | Should -Be 5

                { Add-JiraFilterPermission -Filter $filters -Type "Global" } | Should -Not -Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 5 -Scope It
            }

            It "can find a filter by it's Id" {
                { Add-JiraFilterPermission -Id 1 -Type "Global" } | Should -Not -Throw

                Assert-MockCalled -CommandName Get-JiraFilter -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "allows for the filter's Id to be passed over the pipeline" {
                { 1,2 | Add-JiraFilterPermission -Type "Global" } | Should -Not -Throw

                Assert-MockCalled -CommandName Get-JiraFilter -ModuleName JiraPS -Exactly -Times 2 -Scope It
            }

            It "can process mutiple FilterIds" {
                { Add-JiraFilterPermission -Id 1,2,3,4,5 -Type "Global" } | Should -Not -Throw

                Assert-MockCalled -CommandName Get-JiraFilter -ModuleName JiraPS -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 5 -Scope It
            }

            It "accepts the 5 known permission types" {
                { Add-JiraFilterPermission -Id 1 -Type "lorem" } | Should -Throw
                { Add-JiraFilterPermission -Id 1 -Type "Invalid" } | Should -Throw

                { Add-JiraFilterPermission -Id 1 -Type "Global" } | Should -Not -Throw
                { Add-JiraFilterPermission -Id 1 -Type "Group" } | Should -Not -Throw
                { Add-JiraFilterPermission -Id 1 -Type "Project" } | Should -Not -Throw
                { Add-JiraFilterPermission -Id 1 -Type "ProjectRole" } | Should -Not -Throw
                { Add-JiraFilterPermission -Id 1 -Type "Authenticated" } | Should -Not -Throw
            }

            It "does not validate -Value" {
                { Add-JiraFilterPermission -Id 1 -Type "Global" -Value "invalid" } | Should -Not -Throw
                { Add-JiraFilterPermission -Id 1 -Type "Group" -Value "not a group" } | Should -Not -Throw
                { Add-JiraFilterPermission -Id 1 -Type "Project" -Value "not a project" } | Should -Not -Throw
                { Add-JiraFilterPermission -Id 1 -Type "ProjectRole" -Value "not a Role" } | Should -Not -Throw
                { Add-JiraFilterPermission -Id 1 -Type "Authenticated" -Value "invalid" } | Should -Not -Throw
            }

            It "constructs a valid request Body for type 'Global'" {
                { Add-JiraFilterPermission -Id 12844 -Type "Global" } | Should -Not -Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'Post' -and
                    $URI -like '*/rest/api/*/filter/12844/permission' -and
                    $Body -match '"type":\s*"global"' -and
                    $Body -notmatch ','
                }
            }

            It "constructs a valid request Body for type 'Authenticated'" {
                { Add-JiraFilterPermission -Id 12844 -Type "Authenticated" } | Should -Not -Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'Post' -and
                    $URI -like '*/rest/api/*/filter/12844/permission' -and
                    $Body -match '"type":\s*"authenticated"' -and
                    $Body -notmatch ","
                }
            }

            It "constructs a valid request Body for type 'Group'" {
                { Add-JiraFilterPermission -Id 12844 -Type "Group" -Value "administrators" } | Should -Not -Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'Post' -and
                    $URI -like '*/rest/api/*/filter/12844/permission' -and
                    $Body -match '"type":\s*"group"' -and
                    $Body -match '"groupname":\s*"administrators"'
                }
            }

            It "constructs a valid request Body for type 'Project'" {
                { Add-JiraFilterPermission -Id 12844 -Type "Project" -Value "11822" } | Should -Not -Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'Post' -and
                    $URI -like '*/rest/api/*/filter/12844/permission' -and
                    $Body -match '"type":\s*"project"' -and
                    $Body -match '"projectId":\s*"11822"'
                }
            }

            It "constructs a valid request Body for type 'ProjectRole'" {
                { Add-JiraFilterPermission -Id 12844 -Type "ProjectRole" -Value "11822" } | Should -Not -Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Method -eq 'Post' -and
                    $URI -like '*/rest/api/*/filter/12844/permission' -and
                    $Body -match '"type":\s*"projectRole"' -and
                    $Body -match '"projectRoleId":\s*"11822"'
                }
            }
        }
    }
}
