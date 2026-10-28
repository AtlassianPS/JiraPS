#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Get-JiraField" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'

            # In my Jira instance, this returns 34 objects. I've stripped it down quite a bit for testing.
            $script:restResult = @"
[
    {
        "id": "issuetype",
        "name": "Issue Type",
        "custom": false,
        "orderable": true,
        "navigable": true,
        "searchable": true,
        "clauseNames": [
            "issuetype",
            "type"
        ],
        "schema": {
            "type": "issuetype",
            "system": "issuetype"
        }
    },
    {
        "id": "project",
        "name": "Project",
        "custom": false,
        "orderable": false,
        "navigable": true,
        "searchable": true,
        "clauseNames": [
            "project"
        ],
        "schema": {
            "type": "project",
            "system": "project"
        }
    },
    {
        "id": "status",
        "name": "Status",
        "custom": false,
        "orderable": false,
        "navigable": true,
        "searchable": true,
        "clauseNames": [
            "status"
        ],
        "schema": {
            "type": "status",
            "system": "status"
        }
    },
    {
        "id": "issuekey",
        "name": "Key",
        "custom": false,
        "orderable": false,
        "navigable": true,
        "searchable": false,
        "clauseNames": [
            "id",
            "issue",
            "issuekey",
            "key"
        ]
    },
    {
        "id": "description",
        "name": "Description",
        "custom": false,
        "orderable": true,
        "navigable": true,
        "searchable": true,
        "clauseNames": [
            "description"
        ],
        "schema": {
            "type": "string",
            "system": "description"
        }
    },
    {
        "id": "summary",
        "name": "Summary",
        "custom": false,
        "orderable": true,
        "navigable": true,
        "searchable": true,
        "clauseNames": [
            "summary"
        ],
        "schema": {
            "type": "string",
            "system": "summary"
        }
    },
    {
        "id": "reporter",
        "name": "Reporter",
        "custom": false,
        "orderable": true,
        "navigable": true,
        "searchable": true,
        "clauseNames": [
            "reporter"
        ],
        "schema": {
            "type": "user",
            "system": "reporter"
        }
    },
    {
        "id": "comment",
        "name": "Comment",
        "custom": false,
        "orderable": true,
        "navigable": false,
        "searchable": true,
        "clauseNames": [
            "comment"
        ],
        "schema": {
            "type": "array",
            "items": "comment",
            "system": "comment"
        }
    }
]
"@
            #endregion Definitions

            #region Mocks
            Mock Invoke-JiraRequest -ModuleName JiraPS -ParameterFilter { $Method -eq 'Get' -and $Uri -eq "/rest/api/2/field" } {
                Write-MockDebugInfo 'Invoke-JiraRequest' 'Method', 'Uri'
                ConvertFrom-Json $restResult
            }

            Mock ConvertTo-JiraField {
                Write-MockDebugInfo 'ConvertTo-JiraField' 'InputObject'
                $InputObject
            }
            #endregion Mocks
        }

        Describe "Behavior" {
            It "gets all fields in Jira if called with no parameters" {
                $allResults = Get-JiraField
                $allResults | Should -Not -BeNullOrEmpty
                @($allResults).Count | Should -Be @((ConvertFrom-Json -InputObject $restResult)).Count

                Should -Invoke Invoke-JiraRequest -ModuleName JiraPS -Exactly -Times 1
            }

            It "gets a specified field if a field ID is provided" {
                $oneResult = Get-JiraField -Field issuetype
                $oneResult | Should -Not -BeNullOrEmpty
                $oneResult.ID | Should -Be 'issuetype'
                $oneResult.Name | Should -Be 'Issue Type'
            }

            It "gets a specified issue type if an issue type name is provided" {
                $oneResult = Get-JiraField -Field 'Issue Type'
                $oneResult | Should -Not -BeNullOrEmpty
                $oneResult.ID | Should -Be 'issuetype'
                $oneResult.Name | Should -Be 'Issue Type'
            }

            Context 'Typed field references' {
                It 'uses the ID from a returned field object' {
                    $field = [AtlassianPS.JiraPS.Field]@{ Id = 'issuetype'; Name = 'Issue Type' }

                    $result = @($field | Get-JiraField)

                    $result.Count | Should -Be 1
                    $result[0].Id | Should -Be 'issuetype'
                }

                It 'prefers the field ID over a conflicting display name' {
                    $field = [AtlassianPS.JiraPS.Field]@{ Id = 'issuetype'; Name = 'Summary' }

                    $result = @(Get-JiraField -Field $field)

                    $result.Count | Should -Be 1
                    $result[0].Id | Should -Be 'issuetype'
                    $result[0].Name | Should -Be 'Issue Type'
                }

                It 'does not fall back to the name when a returned field ID is stale' {
                    $field = [AtlassianPS.JiraPS.Field]@{ Id = 'customfield_deleted'; Name = 'Issue Type' }

                    $result = @(Get-JiraField -Field $field)

                    $result.Count | Should -Be 0
                }
            }

            It "handles positional parameters correctly" {
                $oneResult = Get-JiraField 'Issue Type'
                $oneResult | Should -Not -BeNullOrEmpty
                $oneResult.ID | Should -Be issuetype
                $oneResult.Name | Should -Be 'Issue Type'
            }

            It "uses ConvertTo-JiraField to beautify output" {
                $script:JiraCache = @{}
                Get-JiraField | Out-Null
                Should -Invoke ConvertTo-JiraField
            }
        }

        Describe "Caching Behavior" {
            BeforeEach {
                $script:JiraCache = @{}
            }

            It 'refreshes one catalogue for <InputMode> selectors' -ForEach @(
                @{ InputMode = 'array' }
                @{ InputMode = 'pipeline' }
            ) {
                $result = if ($InputMode -eq 'array') { @(Get-JiraField -Field 'issuetype', 'summary' -Refresh) }
                else { @('issuetype', 'summary' | Get-JiraField -Refresh) }

                $result.Id | Should -Be @('issuetype', 'summary')
                Should -Invoke Invoke-JiraRequest -Exactly -Times 1 -ParameterFilter { $BypassCache }
            }

        }
    }
}
