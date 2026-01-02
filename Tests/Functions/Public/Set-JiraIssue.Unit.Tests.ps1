#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
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
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
                $object
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'InputObject', 'Credential'
                $object = [PSCustomObject] @{
                    'id'      = $testJson.id
                    'key'     = $testJson.key
                    'restUrl' = $testJson.self
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.Issue')
                $object
            }

            Mock Resolve-JiraUser -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraUser' 'InputObject', 'Exact', 'Credential'
                $object = [PSCustomObject] @{
                    'Name'    = $InputObject
                    'RestUrl' = "$jiraServer/rest/api/2/user?username=$InputObject"
                }
                $object.PSObject.TypeNames.Insert(0, 'JiraPS.User')
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

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            Context "Issue Update" {
                It "Invokes the Jira API to update an issue" {
                    { Set-JiraIssue -Issue "IT-3676" -Summary "Test summary" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/issue/41701'
                    }
                }

                It "Invokes the Jira API to update an issue from the pipeline" {
                    { Get-JiraIssue "IT-3676" | Set-JiraIssue -Summary "Test summary" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }
            }

            Context "Summary and Description Modification" {
                It "Modifies the summary" {
                    { Set-JiraIssue -Issue "IT-3676" -Summary "new summary" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/issue/41701' -and
                        $Body -match "`"summary`"" -and
                        $Body -match "`"new summary`""
                    }
                }

                It "Modifies the description" {
                    { Set-JiraIssue -Issue "IT-3676" -Description "new description" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
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

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/issue/41701/assignee' -and
                        $Body -match "`"name`"" -and
                        $Body -match "`"testUser`""
                    }
                }

                It "Sets the assignee to unassigned when passed `"unassigned`"" {
                    { Set-JiraIssue -Issue "IT-3676" -Assignee "unassigned" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/issue/41701/assignee' -and
                        $Body -match "`"name`":\s*null"
                    }
                }

                It "Sets the assignee to default assignee when passed `"default`"" {
                    { Set-JiraIssue -Issue "IT-3676" -Assignee "default" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/issue/41701/assignee' -and
                        $Body -match "`"name`":\s*`"-1`""
                    }
                }
            }

            Context "Multiple Field Updates" {
                It "Updates summary and assignee (separate API calls)" {
                    { Set-JiraIssue -Issue "IT-3676" -Summary "new summary" -Assignee "testUser" } | Should -Not -Throw

                    # One call for summary (fields update)
                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/issue/41701' -and
                        $Body -match "`"summary`""
                    }

                    # One call for assignee
                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/issue/41701/assignee'
                    }
                }

                It "Calls Invoke-JiraMethod multiple times when assignee is provided with other fields" {
                    { Set-JiraIssue -Issue "IT-3676" -Summary "new summary" -Description "new description" -Assignee "testUser" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -Scope It
                }
            }

            Context "Label Updates" {
                It "Delegates label updates to Set-JiraIssueLabel" {
                    { Set-JiraIssue -Issue "IT-3676" -Label "label1", "label2" } | Should -Not -Throw

                    Should -Invoke -CommandName Set-JiraIssueLabel -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
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

                    Should -Invoke -CommandName Get-JiraField -ModuleName JiraPS -Exactly -Times 1 -Scope It
                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Body -match '"customfield_10001":[\s\n]*\[[\s\n]*\{[\s\n]*"set":[\s\n]*"test value"'
                    }
                }
            }

            Context "Comment Addition" {
                It "Adds a comment using the -AddComment parameter" {
                    { Set-JiraIssue -Issue "IT-3676" -AddComment "test comment" } | Should -Not -Throw

                    $regexString = '"comment\":[\s\n]*\[[\s\n]*\{[\s\n]*\"add\":[\s\n]*\{[\s\n]*\"body\":\s*\"test comment\"'

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {
                        $Body -match $regexString
                    }
                }
            }
        }

        Describe "Input Validation" {
            Context "Positive cases" {
                It "accepts an issue key string" {
                    { Set-JiraIssue -Issue "IT-3676" -Summary "test" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "accepts an issue object" {
                    { Set-JiraIssue -Issue (Get-JiraIssue "IT-3676") -Summary "test" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }

                It "accepts multiple issues from the pipeline" {
                    { Get-JiraIssue "IT-3676", "IT-3676" | Set-JiraIssue -Summary "test" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
                }
            }

            Context "Negative cases" {
                # TODO: Add negative test cases
            }
        }
    }
}
