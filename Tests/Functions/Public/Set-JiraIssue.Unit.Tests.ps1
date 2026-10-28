#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

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

            Mock Get-JiraIssue -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key', 'Credential'
                $object = [AtlassianPS.JiraPS.Issue]@{
                    id      = $testJson.id
                    key     = $testJson.key
                    restUrl = $testJson.self
                }
                $object
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPS {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'InputObject', 'Credential'
                $object = [AtlassianPS.JiraPS.Issue]@{
                    id      = $testJson.id
                    key     = $testJson.key
                    restUrl = $testJson.self
                }
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
                    [PSCustomObject]@{
                        Id   = 'customfield_99999'
                        Name = 'FallbackField'
                    }
                )
            }

            Mock Get-JiraIssueEditMetadata -ModuleName JiraPS {
                Write-MockDebugInfo 'Get-JiraIssueEditMetadata' 'Issue', 'Credential'
                $field = [PSCustomObject]@{
                    Id     = 'customfield_10001'
                    Name   = 'CustomField1'
                    Schema = [PSCustomObject]@{ type = 'string' }
                }
                $field.PSObject.TypeNames.Insert(0, 'JiraPS.EditMetaField')
                $field
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Put' -and
                (
                    $URI -like "$jiraServer/rest/api/*/issue/41701" -or
                    $URI -like "$jiraServer/rest/api/*/issue/IT-3676"
                )
            } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri', 'Body'
                # Should not need to return anything for an update
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Put' -and
                (
                    $URI -like "$jiraServer/rest/api/*/issue/41701/assignee" -or
                    $URI -like "$jiraServer/rest/api/*/issue/IT-3676/assignee"
                )
            } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri', 'Body'
                # Should not need to return anything for an assignee update
            }

            Mock Invoke-JiraRequest -ModuleName JiraPS {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraRequest"
            }
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "Issue Update" {

                It "Invokes the Jira API to update an issue from the pipeline" {
                    Mock Resolve-JiraIssueObject { $InputObject }
                    Mock Invoke-JiraRequest {} -ParameterFilter { $Method -eq 'Put' -and $URI -eq "$jiraServer/rest/api/2/issue/41702" }
                    $issues = @(
                        [AtlassianPS.JiraPS.Issue]@{ Id = '41701'; Key = 'IT-3676'; RestURL = "$jiraServer/rest/api/2/issue/41701" }
                        [AtlassianPS.JiraPS.Issue]@{ Id = '41702'; Key = 'IT-3677'; RestURL = "$jiraServer/rest/api/2/issue/41702" }
                    )
                    $issues | Set-JiraIssue -Summary 'Test summary'

                    Should -Invoke Invoke-JiraRequest -Exactly -Times 2
                    Should -Invoke Invoke-JiraRequest -Exactly -Times 1 -ParameterFilter {
                        $URI -eq "$jiraServer/rest/api/2/issue/41701" -and ($Body | ConvertFrom-Json).update.summary[0].set -eq 'Test summary'
                    }
                    Should -Invoke Invoke-JiraRequest -Exactly -Times 1 -ParameterFilter {
                        $URI -eq "$jiraServer/rest/api/2/issue/41702" -and ($Body | ConvertFrom-Json).update.summary[0].set -eq 'Test summary'
                    }
                }
            }

            Context "Summary and Description Modification" {
                It "Modifies the summary" {
                    { Set-JiraIssue -Key "IT-3676" -Summary "new summary" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/issue/41701' -and
                        $Body -match "`"summary`"" -and
                        $Body -match "`"new summary`""
                    }
                }

                It "Modifies the description" {
                    { Set-JiraIssue -Issue "IT-3676" -Description "new description" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
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

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/issue/41701/assignee' -and
                        $Body -match "`"name`"" -and
                        $Body -match "`"testUser`""
                    }
                }

                It "Unassigns the issue when -Unassign switch is specified" {
                    { Set-JiraIssue -Issue "IT-3676" -Unassign } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/issue/41701/assignee' -and
                        $Body -match "`"name`":\s*null"
                    }
                }

                It "sends the project-default username to the Data Center assignee endpoint" {
                    $script:defaultAssigneeRequest = $null
                    Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' -and $URI -like '*/assignee' } {
                        $script:defaultAssigneeRequest = @{ Method = $Method; Uri = $URI; Body = $Body }
                    }

                    Set-JiraIssue -Issue "IT-3676" -UseDefaultAssignee -ErrorAction Stop

                    $defaultAssigneeRequest.Method | Should -Be 'Put'
                    $defaultAssigneeRequest.Uri | Should -Be "$jiraServer/rest/api/2/issue/41701/assignee"
                    $payload = $defaultAssigneeRequest.Body | ConvertFrom-Json
                    @($payload.PSObject.Properties).Count | Should -Be 1
                    $payload.name | Should -Be '-1'
                }

                It "Throws when -Assignee is given an empty string" {
                    { Set-JiraIssue -Issue "IT-3676" -Assignee "" } | Should -Throw
                }

                It "Throws when -Assignee is given a whitespace-only string" {
                    { Set-JiraIssue -Issue "IT-3676" -Assignee "   " } | Should -Throw -ExpectedMessage "*empty or whitespace*"
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

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $URI -like '*/rest/api/*/issue/41701/assignee' -and
                        $Body -match "`"name`":\s*null"
                    }
                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $URI -like '*/rest/api/*/issue/41701' -and
                        $Body -match "`"summary`""
                    }
                }

                It "Allows -UseDefaultAssignee together with other modifying parameters (Summary)" {
                    { Set-JiraIssue -Issue "IT-3676" -Summary "new summary" -UseDefaultAssignee } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $URI -like '*/rest/api/*/issue/41701/assignee' -and
                        $Body -match "`"name`":\s*`"-1`""
                    }
                }

                It "Allows -Unassign together with -Fields" {
                    {
                        Set-JiraIssue -Issue "IT-3676" -Fields @{ customfield_10001 = 'test' } -Unassign
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $URI -like '*/rest/api/*/issue/41701/assignee' -and
                        $Body -match "`"name`":\s*null"
                    }

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
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
                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/issue/41701' -and
                        $Body -match "`"summary`""
                    }

                    # One call for assignee
                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Put' -and
                        $URI -like '*/rest/api/*/issue/41701/assignee'
                    }
                }

            }

            Context "Label Updates" {
                It 'normalizes explicitly null labels to an empty clear operation' {
                    Set-JiraIssue -Issue 'IT-3676' -Label $null
                    Should -Invoke Invoke-JiraRequest -Exactly 1 -ParameterFilter {
                        $payload = ConvertFrom-Json $Body
                        $payload.update.labels[0].set.Count -eq 0
                    }
                }

                It "includes explicitly bound labels in the issue update" {
                    { Set-JiraIssue -Issue "IT-3676" -Label "label1", "label2" } | Should -Not -Throw

                    Should -Invoke Invoke-JiraRequest -Exactly 1 -ParameterFilter {
                        $payload = ConvertFrom-Json $Body
                        $payload.update.labels[0].set -contains "label1" -and $payload.update.labels[0].set -contains "label2"
                    }
                }
            }

            Context "Custom Fields" {
                It "Sets a custom field via the -Fields parameter using edit metadata" {
                    {
                        $fields = @{ "customfield_10001" = "test value" }
                        Set-JiraIssue -Issue "IT-3676" -Fields $fields
                    } | Should -Not -Throw

                    # Field is in edit metadata — Get-JiraField should not be called
                    Should -Invoke -CommandName Get-JiraField -ModuleName JiraPS -Exactly -Times 0
                    Should -Invoke -CommandName Get-JiraIssueEditMetadata -ModuleName JiraPS -Exactly -Times 1
                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Body -match '"customfield_10001":[\s\n]*\[[\s\n]*\{[\s\n]*"set":[\s\n]*"test value"'
                    }
                }

                It "falls back to Get-JiraField for fields not in edit metadata" {
                    # Override edit metadata to return empty — customfield_99999
                    # is only present in the Get-JiraField mock, so it should
                    # trigger the fallback path.
                    Mock Get-JiraIssueEditMetadata -ModuleName JiraPS { @() }

                    {
                        $fields = @{ "customfield_99999" = "fallback value" }
                        Set-JiraIssue -Issue "IT-3676" -Fields $fields
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Get-JiraField -ModuleName JiraPS -Exactly -Times 1
                }

                It "fetches edit metadata and the global list at most once across multiple -Fields keys" {
                    # Override edit metadata so both keys fall back to Get-JiraField.
                    Mock Get-JiraIssueEditMetadata -ModuleName JiraPS { @() }

                    Set-JiraIssue -Issue "IT-3676" -Fields @{
                        customfield_10001 = 'a'
                        customfield_99999 = 'b'
                    }

                    Should -Invoke -CommandName Get-JiraField -ModuleName JiraPS -Exactly -Times 1
                }
            }

            Context "Comment Addition" {
                It "Adds a comment using the -AddComment parameter" {
                    { Set-JiraIssue -Issue "IT-3676" -AddComment "test comment" } | Should -Not -Throw

                    $regexString = '"comment\":[\s\n]*\[[\s\n]*\{[\s\n]*\"add\":[\s\n]*\{[\s\n]*\"body\":\s*\"test comment\"'

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                        $Body -match $regexString
                    }
                }
            }
        }

        Describe "Input Validation" {
            Context "Positive cases" {

                It "accepts an issue object" {
                    { Set-JiraIssue -Issue (Get-JiraIssue "IT-3676") -Summary "test" } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1
                }

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

                Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $Method -eq 'Put' -and
                    $URI -like '*/rest/api/*/issue/41701/assignee' -and
                    $Body -match "`"accountId`"" -and
                    $Body -match "`"$testAccountId`""
                }
            }

            It "sends the project-default accountId to the Cloud assignee endpoint" {
                $script:defaultAssigneeRequest = $null
                Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter { $Method -eq 'Put' -and $URI -like '*/assignee' } {
                    $script:defaultAssigneeRequest = @{ Method = $Method; Uri = $URI; Body = $Body }
                }

                Set-JiraIssue -Issue "IT-3676" -UseDefaultAssignee -ErrorAction Stop

                $defaultAssigneeRequest.Method | Should -Be 'Put'
                $defaultAssigneeRequest.Uri | Should -Be "$jiraServer/rest/api/3/issue/41701/assignee"
                $payload = $defaultAssigneeRequest.Body | ConvertFrom-Json
                @($payload.PSObject.Properties).Count | Should -Be 1
                $payload.accountId | Should -Be '-1'
            }

            It "Sends accountId:null when -Unassign on Cloud deployment" {
                { Set-JiraIssue -Issue "IT-3676" -Unassign } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $Method -eq 'Put' -and
                    $URI -like '*/rest/api/*/issue/41701/assignee' -and
                    $Body -match "`"accountId`":\s*null"
                }
            }

            It "Wraps -Description into ADF on Cloud" {
                { Set-JiraIssue -Issue "IT-3676" -Description "rewritten description" } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $payload = $Body | ConvertFrom-Json
                    $set = $payload.update.description[0].set
                    $set.type -eq 'doc' -and
                    $set.version -eq 1 -and
                    $set.content[0].type -eq 'paragraph' -and
                    $set.content[0].content[0].text -eq 'rewritten description'
                }
            }

            It "Wraps -AddComment into ADF on Cloud" {
                { Set-JiraIssue -Issue "IT-3676" -AddComment "follow-up comment" } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $payload = $Body | ConvertFrom-Json
                    $body = $payload.update.comment[0].add.body
                    $body.type -eq 'doc' -and
                    $body.version -eq 1 -and
                    $body.content[0].type -eq 'paragraph' -and
                    $body.content[0].content[0].text -eq 'follow-up comment'
                }
            }

            It "uses the v3 issue endpoint on Cloud" {
                { Set-JiraIssue -Issue "IT-3676" -Description "rewritten description" } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $Method -eq 'Put' -and
                    $URI -eq "$jiraServer/rest/api/3/issue/41701"
                }
            }

            It "uses the v3 assignee endpoint on Cloud" {
                { Set-JiraIssue -Issue "IT-3676" -Assignee "testUser" } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $Method -eq 'Put' -and
                    $URI -eq "$jiraServer/rest/api/3/issue/41701/assignee"
                }
            }

            It "Wraps a rich-text field passed via -Fields into ADF on Cloud" {
                # On Cloud, the v3 issue endpoint also rejects raw strings
                # in rich-text fields supplied via -Fields. The cmdlet
                # must use the field's schema (via Test-JiraRichTextField)
                # to wrap the value in ADF, matching the behaviour of the
                # explicit -Description parameter.
                Mock Get-JiraField -ModuleName JiraPS {
                    Write-MockDebugInfo 'Get-JiraField' 'Credential'
                    @(
                        [PSCustomObject]@{
                            Id     = 'description'
                            Name   = 'Description'
                            Schema = [PSCustomObject]@{ type = 'string'; system = 'description' }
                        }
                    )
                }

                { Set-JiraIssue -Issue "IT-3676" -Fields @{ description = "via fields" } } |
                    Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $payload = $Body | ConvertFrom-Json
                    $set = $payload.update.description[0].set
                    $set.type -eq 'doc' -and
                    $set.content[0].content[0].text -eq 'via fields'
                }
            }

            It "Leaves a non-rich-text field passed via -Fields verbatim on Cloud" {
                Mock Get-JiraField -ModuleName JiraPS {
                    Write-MockDebugInfo 'Get-JiraField' 'Credential'
                    @(
                        [PSCustomObject]@{
                            Id     = 'customfield_10001'
                            Name   = 'CustomField1'
                            Schema = [PSCustomObject]@{
                                type   = 'string'
                                custom = 'com.atlassian.jira.plugin.system.customfieldtypes:textfield'
                            }
                        }
                    )
                }

                { Set-JiraIssue -Issue "IT-3676" -Fields @{ customfield_10001 = "plain" } } |
                    Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $payload = $Body | ConvertFrom-Json
                    $set = $payload.update.customfield_10001[0].set
                    $set -is [string] -and $set -eq 'plain'
                }
            }
        }
    }
}
