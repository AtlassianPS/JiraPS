#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraWorklogitem" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:jiraUsername = 'powershell-test'
            $script:jiraUserDisplayName = 'PowerShell Test User'
            $script:jiraUserEmail = 'noreply@example.com'
            $script:issueID = 41701
            $script:issueKey = 'IT-3676'
            $script:worklogitemID = 73040
            $script:commentBody = "Test description"
            $script:worklogTimeSpent = "1h"
            $script:worklogTimeSpentSeconds = "3600"

            $script:sampleJson = @"
{
    "id": "$worklogitemID",
    "self": "$jiraServer/rest/api/2/issue/$issueID/worklog/$worklogitemID",
    "comment": "Test description",
    "created": "2015-05-01T16:24:38.000-0500",
    "updated": "2015-05-01T16:24:38.000-0500",
    "started": "2017-02-23T22:21:00.000-0500",
    "timeSpent": "1h",
    "timeSpentSeconds": "3600",
    "author": {
        "self": "$jiraServer/rest/api/2/user?username=powershell-test",
        "name": "$jiraUsername",
        "emailAddress": "$jiraUserEmail",
        "avatarUrls": {
            "48x48": "$jiraServer/secure/useravatar?avatarId=10202",
            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10202",
            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10202",
            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10202"
        },
        "displayName": "$jiraUserDisplayName",
        "active": true
    },
    "updateAuthor": {
        "self": "$jiraServer/rest/api/2/user?username=powershell-test",
        "name": "powershell-test",
        "emailAddress": "$jiraUserEmail",
        "avatarUrls": {
            "48x48": "$jiraServer/secure/useravatar?avatarId=10202",
            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10202",
            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10202",
            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10202"
        },
        "displayName": "$jiraUserDisplayName",
        "active": true
    }
}
"@
            $script:sampleObject = ConvertFrom-Json -InputObject $sampleJson
            #endregion Definitions

            #region Mocks
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "Object Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraWorklogitem -InputObject $sampleObject
                }

                It "creates PSObject from JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                }

                It "returns AtlassianPS.JiraPS.Worklogitem" {
                    $result.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.Worklogitem'
                    $result | Should -BeOfType [AtlassianPS.JiraPS.Worklogitem]
                }
            }

            Context "Property Mapping" {
                BeforeAll {
                    $script:result = ConvertTo-JiraWorklogitem -InputObject $sampleObject
                }

                It "defines 'Id' property with correct value" {
                    $result.Id | Should -Be $worklogitemID
                }

                It "defines 'Comment' property with correct value" {
                    $result.Comment | Should -Be $commentBody
                }

                It "defines 'RestUrl' property with correct value" {
                    $result.RestUrl | Should -Be "$jiraServer/rest/api/2/issue/41701/worklog/$worklogitemID"
                }

                It "defines 'Created' property with correct value" {
                    $result.Created | Should -Be ([System.DateTimeOffset](Get-Date '2015-05-01T16:24:38.000-0500'))
                }

                It "defines 'Updated' property with correct value" {
                    $result.Updated | Should -Be ([System.DateTimeOffset](Get-Date '2015-05-01T16:24:38.000-0500'))
                }

                It "defines 'Started' property with correct value" {
                    $result.Started | Should -Be ([System.DateTimeOffset](Get-Date '2017-02-23T22:21:00.000-0500'))
                }

                It "defines 'TimeSpent' property with correct value" {
                    $result.TimeSpent | Should -Be $worklogTimeSpent
                }

                It "defines 'TimeSpentSeconds' property with correct value" {
                    $result.TimeSpentSeconds | Should -Be $worklogTimeSpentSeconds
                }
            }

            Context "Type Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraWorklogitem -InputObject $sampleObject
                }

                It "converts Id to numeric type" {
                    $result.Id | Should -BeOfType ([System.ValueType])
                    $result.Id.GetType() | Should -BeIn @([int], [long], [int64])
                }

                It "converts Created to correct type" {
                    $result.Created | Should -BeOfType [System.DateTimeOffset]
                }

                It "converts Updated to correct type" {
                    $result.Updated | Should -BeOfType [System.DateTimeOffset]
                }

                It "converts Started to correct type" {
                    $result.Started | Should -BeOfType [System.DateTimeOffset]
                }
            }

            Context "Pipeline Support" {
                It "accepts pipeline input" {
                    $result = $sampleObject | ConvertTo-JiraWorklogitem
                    $result | Should -Not -BeNullOrEmpty
                }
            }

            Context "Atlassian Document Format comment" {
                It "renders an ADF comment payload back to plain text" {
                    # Cloud worklog GET responses return 'comment' as an ADF doc,
                    # not a string; ConvertTo-JiraWorklogitem must render it.
                    $cloudJson = @"
{
    "id": "$worklogitemID",
    "self": "$jiraServer/rest/api/3/issue/$issueID/worklog/$worklogitemID",
    "comment": {
        "version": 1,
        "type": "doc",
        "content": [
            {
                "type": "paragraph",
                "content": [
                    { "type": "text", "text": "Cloud worklog comment." }
                ]
            }
        ]
    },
    "created": "2015-05-01T16:24:38.000-0500",
    "updated": "2015-05-01T16:24:38.000-0500",
    "started": "2017-02-23T22:21:00.000-0500",
    "timeSpent": "1h",
    "timeSpentSeconds": "3600"
}
"@
                    $cloudObject = ConvertFrom-Json -InputObject $cloudJson
                    $rendered = ConvertTo-JiraWorklogitem -InputObject $cloudObject

                    $rendered.Comment | Should -BeOfType [string]
                    $rendered.Comment | Should -Be 'Cloud worklog comment.'
                }

                It "passes through `$null comment without error" {
                    $jsonNoComment = @"
{
    "id": "$worklogitemID",
    "self": "$jiraServer/rest/api/2/issue/$issueID/worklog/$worklogitemID",
    "created": "2015-05-01T16:24:38.000-0500",
    "started": "2017-02-23T22:21:00.000-0500",
    "timeSpent": "1h",
    "timeSpentSeconds": "3600"
}
"@
                    $object = ConvertFrom-Json -InputObject $jsonNoComment
                    { ConvertTo-JiraWorklogitem -InputObject $object } | Should -Not -Throw
                    (ConvertTo-JiraWorklogitem -InputObject $object).Comment | Should -BeNullOrEmpty
                }
            }
        }
    }
}
