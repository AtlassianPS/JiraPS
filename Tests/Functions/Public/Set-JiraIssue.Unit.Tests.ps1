#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Set-JiraIssue" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = "https://jira.example.com"

            $script:testJsonIssue = @"
{
    "id": "41701",
    "key": "IT-3676",
    "self": "$jiraServer/rest/api/2/issue/41701",
    "fields": {
        "summary": "Test summary",
        "created": "2015-11-20T09:39:27.000+0100",
        "priority": {
            "id": "3",
            "name": "Medium"
        },
        "status": {
            "id": "1",
            "name": "Open"
        }
    }
}
"@

            $script:testJson = $testJsonIssue | ConvertFrom-Json
            #endregion Definitions

            #region Mocks
            Mock Test-JiraCloudServer -ModuleName JiraPS { $false }

            Mock Get-JiraConfigServer -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Get-JiraIssue -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key', 'Credential'
                $object = [PSCustomObject] @{
                    'id'      = $testJson.id
                    'key'     = $testJson.key
                    'restUrl' = $testJson.self
                }
                $object.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.Issue')
                $object
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'InputObject', 'Credential'
                $object = [PSCustomObject] @{
                    'id'      = $testJson.id
                    'key'     = $testJson.key
                    'restUrl' = $testJson.self
                }
                $object.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.Issue')
                $object
            }

            Mock Resolve-JiraUser -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraUser' 'InputObject', 'Exact', 'Credential'
                $object = [PSCustomObject] @{
                    'Name'    = $InputObject
                    'RestUrl' = "$jiraServer/rest/api/2/user?username=$InputObject"
                }
                $object.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.User')
                $object
            }

            Mock Get-JiraField -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraField' 'Credential'
                @(
                    [PSCustomObject]@{
                        Id   = 'customfield_10001'
                        Name = 'CustomField1'
                    }
                )
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Put' -and
                (
                    $URI -like "$jiraServer/rest/api/*/issue/41701" -or
                    $URI -like "$jiraServer/rest/api/*/issue/IT-3676"
                )
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
                # Should not need to return anything for an update
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Put' -and
                (
                    $URI -like "$jiraServer/rest/api/*/issue/41701/assignee" -or
                    $URI -like "$jiraServer/rest/api/*/issue/IT-3676/assignee"
                )
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
                # Should not need to return anything for an assignee update
            }

            Mock Set-JiraIssueLabel -ModuleName JiraPS {
                Write-MockDebugInfo 'Set-JiraIssueLabel' 'Issue', 'Set', 'Add', 'Remove', 'Clear', 'Credential'
                # Should not need to return anything for an update
            }

            Mock Invoke-JiraMethod -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Set-JiraIssue
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Issue'; type = 'Object[]' }
                    @{ parameter = 'Summary'; type = 'String' }
                    @{ parameter = 'Description'; type = 'String' }
                    @{ parameter = 'Assignee'; type = 'Object' }
                    @{ parameter = 'Unassign'; type = 'Switch' }
                    @{ parameter = 'UseDefaultAssignee'; type = 'Switch' }
                    @{ parameter = 'Label'; type = 'String[]' }
                    @{ parameter = 'AddComment'; type = 'String' }
                    @{ parameter = 'Fields'; type = 'PSCustomObject' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                    @{ parameter = 'PassThru'; type = 'Switch' }
                    @{ parameter = 'SkipNotification'; type = 'Switch' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter -Type $type
                }

                It "has an alias 'Key' for parameter 'Issue'" {
                    $command.Parameters.Item('Issue').Aliases | Should -Contain 'Key'
                }
            }

            Context "Parameter Sets" {
                It "defines parameter set '<setName>'" -TestCases @(
                    @{ setName = 'AssignToUser' }
                    @{ setName = 'Unassign' }
                    @{ setName = 'UseDefaultAssignee' }
                ) {
                    param($setName)
                    $command.ParameterSets.Name | Should -Contain $setName
                }

                It "uses 'AssignToUser' as the default parameter set" {
                    $command.DefaultParameterSet | Should -Be 'AssignToUser'
                }

                It "binds '<parameter>' only to parameter set '<setName>'" -TestCases @(
                    @{ parameter = 'Assignee'; setName = 'AssignToUser' }
                    @{ parameter = 'Unassign'; setName = 'Unassign' }
                    @{ parameter = 'UseDefaultAssignee'; setName = 'UseDefaultAssignee' }
                ) {
                    param($parameter, $setName)
                    $sets = $command.Parameters.Item($parameter).ParameterSets.Keys
                    $sets | Should -HaveCount 1
                    $sets | Should -Contain $setName
                }

                It "makes shared parameter '<parameter>' available in all sets" -TestCases @(
                    @{ parameter = 'Issue' }
                    @{ parameter = 'Summary' }
                    @{ parameter = 'Description' }
                    @{ parameter = 'FixVersion' }
                    @{ parameter = 'Label' }
                    @{ parameter = 'Fields' }
                    @{ parameter = 'AddComment' }
                ) {
                    param($parameter)
                    $command.Parameters.Item($parameter).ParameterSets.Keys | Should -Contain '__AllParameterSets'
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            Context "Issue Update" {
                It "Invokes the Jira API to update an issue" {
                    { Set-JiraIssue -Issue "IT-3676" -Summary "Test summary" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/issue/41701'
                    }
                }

                It "Invokes the Jira API to update an issue from the pipeline" {
                    { Get-JiraIssue "IT-3676" | Set-JiraIssue -Summary "Test summary" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
                }
            }

            Context "Summary and Description Modification" {
                It "Modifies the summary" {
                    { Set-JiraIssue -Issue "IT-3676" -Summary "new summary" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/issue/41701' -and
                        $Body -match "`"summary`"" -and
                        $Body -match "`"new summary`""
                    }
                }

                It "Modifies the description" {
                    { Set-JiraIssue -Issue "IT-3676" -Description "new description" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/issue/41701' -and
                        $Body -match "`"description`"" -and
                        $Body -match "`"new description`""
                    }
                }
            }

            Context "Assignee Modification" {
                It "Sets the assignee to a specified user" {
                    { Set-JiraIssue -Issue "IT-3676" -Assignee "testUser" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/issue/41701/assignee' -and
                        $Body -match "`"name`"" -and
                        $Body -match "`"testUser`""
                    }
                }

                It "Unassigns the issue when -Unassign switch is specified" {
                    { Set-JiraIssue -Issue "IT-3676" -Unassign } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/issue/41701/assignee' -and
                        $Body -match "`"name`":\s*null"
                    }
                }

                It "Sets the assignee to default when -UseDefaultAssignee is specified" {
                    { Set-JiraIssue -Issue "IT-3676" -UseDefaultAssignee } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/issue/41701/assignee' -and
                        $Body -match "`"name`":\s*`"-1`""
                    }
                }

                It "Throws when -Assignee is given an empty string" {
                    { Set-JiraIssue -Issue "IT-3676" -Assignee "" } | Should -Throw
                }

                It "Throws when -Assignee is given a whitespace-only string" {
                    { Set-JiraIssue -Issue "IT-3676" -Assignee "   " } | Should -Throw -ExpectedMessage "*whitespace-only*"
                }

                It "Throws when -Assignee is given `$null" {
                    { Set-JiraIssue -Issue "IT-3676" -Assignee $null } | Should -Throw
                }

                It "Throws when both -Unassign and -Assignee are given" {
                    { Set-JiraIssue -Issue "IT-3676" -Assignee "testUser" -Unassign } | Should -Throw
                }

                It "Throws when both -UseDefaultAssignee and -Assignee are given" {
                    { Set-JiraIssue -Issue "IT-3676" -Assignee "testUser" -UseDefaultAssignee } | Should -Throw
                }

                It "Throws when both -Unassign and -UseDefaultAssignee are given" {
                    { Set-JiraIssue -Issue "IT-3676" -Unassign -UseDefaultAssignee } | Should -Throw
                }

                It "Errors when no modifying parameters are passed" {
                    { Set-JiraIssue -Issue "IT-3676" -ErrorAction Stop } |
                        Should -Throw -ExpectedMessage "*do not change the Issue*"
                }

                It "Allows -Unassign together with other modifying parameters (Summary)" {
                    { Set-JiraIssue -Issue "IT-3676" -Summary "new summary" -Unassign } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $URI -like '*/rest/api/*/issue/41701/assignee' -and
                        $Body -match "`"name`":\s*null"
                    }
                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $URI -like '*/rest/api/*/issue/41701' -and
                        $Body -match "`"summary`""
                    }
                }

                It "Allows -UseDefaultAssignee together with other modifying parameters (Summary)" {
                    { Set-JiraIssue -Issue "IT-3676" -Summary "new summary" -UseDefaultAssignee } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $URI -like '*/rest/api/*/issue/41701/assignee' -and
                        $Body -match "`"name`":\s*`"-1`""
                    }
                }

                It "Allows -Unassign together with -Fields" {
                    {
                        Set-JiraIssue -Issue "IT-3676" -Fields @{ customfield_10001 = 'test' } -Unassign
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $URI -like '*/rest/api/*/issue/41701/assignee' -and
                        $Body -match "`"name`":\s*null"
                    }

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $URI -like '*/rest/api/*/issue/41701' -and
                        $URI -notlike '*/assignee' -and
                        $Body -match '"customfield_10001"'
                    }
                }
            }

            Context "Multiple Field Updates" {
                It "Updates summary and assignee (separate API calls)" {
                    { Set-JiraIssue -Issue "IT-3676" -Summary "new summary" -Assignee "testUser" } | Should -Not -Throw

                    # One call for summary (fields update)
                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/issue/41701' -and
                        $Body -match "`"summary`""
                    }

                    # One call for assignee
                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/issue/41701/assignee'
                    }
                }

                It "Calls Invoke-JiraMethod multiple times when assignee is provided with other fields" {
                    { Set-JiraIssue -Issue "IT-3676" -Summary "new summary" -Description "new description" -Assignee "testUser" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2
                }
            }

            Context "Label Updates" {
                It "Delegates label updates to Set-JiraIssueLabel" {
                    { Set-JiraIssue -Issue "IT-3676" -Label "label1", "label2" } | Should -Not -Throw

                    Should -Invoke -CommandName Set-JiraIssueLabel -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Set -contains "label1" -and $Set -contains "label2"
                    }
                }
            }

            Context "Custom Fields" {
                It "Sets a custom field via the -Fields parameter" {
                    {
                        $fields = @{ "customfield_10001" = "test value" }
                        Set-JiraIssue -Issue "IT-3676" -Fields $fields
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Get-JiraField -ModuleName JiraPS -Exactly -Times 1
                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Body -match '"customfield_10001":[\s\n]*\[[\s\n]*\{[\s\n]*"set":[\s\n]*"test value"'
                    }
                }
            }

            Context "Comment Addition" {
                It "Adds a comment using the -AddComment parameter" {
                    { Set-JiraIssue -Issue "IT-3676" -AddComment "test comment" } | Should -Not -Throw

                    $regexString = '"comment\":[\s\n]*\[[\s\n]*\{[\s\n]*\"add\":[\s\n]*\{[\s\n]*\"body\":\s*\"test comment\"'

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Body -match $regexString
                    }
                }
            }
        }

        Describe "Input Validation" {
            Context "Positive cases" {
                It "accepts an issue key string" {
                    { Set-JiraIssue -Issue "IT-3676" -Summary "test" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
                }

                It "accepts an issue object" {
                    { Set-JiraIssue -Issue (Get-JiraIssue "IT-3676") -Summary "test" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
                }

                It "accepts multiple issues from the pipeline" {
                    { Get-JiraIssue "IT-3676", "IT-3676" | Set-JiraIssue -Summary "test" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1
                }
            }

            Context "Negative cases" {
                # TODO: Add negative test cases
            }
        }

        Describe "Cloud Deployment" {
            BeforeAll {
                $script:testAccountId = '5b10a2844c20165700ede21a'

                Mock Test-JiraCloudServer -ModuleName JiraPS { $true }

                Mock Resolve-JiraUser -ModuleName JiraPS {
                    Write-MockDebugInfo 'Resolve-JiraUser' 'InputObject', 'Exact', 'Credential'
                    $object = [PSCustomObject] @{
                        'Name'      = $InputObject
                        'AccountId' = $testAccountId
                        'RestUrl'   = "$jiraServer/rest/api/2/user?username=$InputObject"
                    }
                    $object.PSObject.TypeNames.Insert(0, 'AtlassianPS.JiraPS.User')
                    $object
                }
            }

            It "Uses accountId for assignee when on Cloud deployment" {
                { Set-JiraIssue -Issue "IT-3676" -Assignee "testUser" } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $Method -eq 'Put' -and
                    $URI -like '*/rest/api/*/issue/41701/assignee' -and
                    $Body -match "`"accountId`"" -and
                    $Body -match "`"$testAccountId`""
                }
            }

            It "Sends accountId:null when -Unassign on Cloud deployment" {
                { Set-JiraIssue -Issue "IT-3676" -Unassign } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $Method -eq 'Put' -and
                    $URI -like '*/rest/api/*/issue/41701/assignee' -and
                    $Body -match "`"accountId`":\s*null"
                }
            }
        }
    }
}
