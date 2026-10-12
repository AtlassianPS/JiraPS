#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {

    Describe 'v3 nested return contracts' -Tag Unit {
        It 'returns typed history items with wire values and offset dates on <deployment>' -TestCases @(
            @{ deployment = 'Cloud'; author = '{"accountId":"cloud-user"}' }
            @{ deployment = 'Data Center'; author = '{"name":"dc-user"}' }
        ) {
            param($author)
            $wire = ConvertFrom-Json @'
{
    "id": "10",
    "created": "2026-10-10T10:11:12.000+0200",
    "items": [
        {
            "field": "status",
            "fieldtype": "jira",
            "fieldId": "status",
            "from": "1",
            "fromString": "Open",
            "to": "2",
            "toString": "Done"
        }
    ]
}
'@
            $wire | Add-Member -NotePropertyName author -NotePropertyValue (ConvertFrom-Json $author)
            $parsed = ConvertTo-JiraIssueHistoryEntry -InputObject $wire
            $parsed.Created.UtcDateTime | Should -Be ([DateTimeOffset]::Parse('2026-10-10T08:11:12Z').UtcDateTime)
            $wire.created = '2026-10-10T10:11:12.000+0200'
            $entry = ConvertTo-JiraIssueHistoryEntry -InputObject $wire
            $entry.GetType() | Should -Be ([AtlassianPS.JiraPS.IssueHistoryEntry])
            $entry.Items.GetType() | Should -Be ([AtlassianPS.JiraPS.IssueHistoryItem[]])
            $entry.Items[0].GetType() | Should -Be ([AtlassianPS.JiraPS.IssueHistoryItem])
            $entry.Items[0].ToString | Should -Be 'Done'
            $entry.Created.Offset | Should -Be ([timespan]::FromHours(2))
            $entry.Author.GetType() | Should -Be ([AtlassianPS.JiraPS.User])
            $entry.ToString() | Should -Be '10'
            $json = $entry | ConvertTo-Json -Depth 10 | ConvertFrom-Json
            $json.Items[0].ToString | Should -Be 'Done'
        }

        It 'keeps declared history per issue and uses null for an unassigned user' {
            $wire = ConvertFrom-Json @'
[
    {
        "id": "1",
        "key": "TEST-1",
        "self": "https://jira.example/rest/api/2/issue/1",
        "fields": {
            "assignee": null
        },
        "changelog": {
            "histories": [
                {
                    "id": "10",
                    "items": []
                }
            ]
        }
    },
    {
        "id": "2",
        "key": "TEST-2",
        "self": "https://jira.example/rest/api/2/issue/2",
        "fields": {}
    }
]
'@
            $issues = @(ConvertTo-JiraIssue -InputObject $wire)
            $issues[0].Assignee | Should -BeNullOrEmpty
            $issues[0].History[0].Id | Should -Be '10'
            $issues[0].History[0].Items.Count | Should -Be 0
            $issues[1].History | Should -BeNullOrEmpty
            $issues[0].PSObject.Properties['History'].MemberType | Should -Be 'Property'
        }

        It 'preserves absent nested reference values (<shape>)' -TestCases @(
            @{ shape = 'omitted'; attachment = '{"id":"1"}'; transition = '{"id":"2"}' }
            @{ shape = 'null'; attachment = '{"id":"1","author":null}'; transition = '{"id":"2","to":null}' }
        ) {
            param($attachment, $transition)
            $convertedAttachment = ConvertTo-JiraAttachment (ConvertFrom-Json $attachment)
            $convertedAttachment.GetType() | Should -Be ([AtlassianPS.JiraPS.Attachment])
            $convertedAttachment.Author | Should -BeNullOrEmpty
            $convertedTransition = ConvertTo-JiraTransition (ConvertFrom-Json $transition)
            $convertedTransition.GetType() | Should -Be ([AtlassianPS.JiraPS.Transition])
            $convertedTransition.ResultStatus | Should -BeNullOrEmpty
        }

        It 'types stable issue fields without replacing extensible custom values' {
            $wire = ConvertFrom-Json @'
{
    "key": "TEST-1",
    "self": "https://jira.example/rest/api/2/issue/1",
    "fields": {
        "issuetype": {
            "id": "1",
            "name": "Bug"
        },
        "priority": {
            "id": "2"
        },
        "resolution": null,
        "components": [
            {
                "id": "3"
            }
        ],
        "worklog": {
            "worklogs": []
        },
        "fixVersions": [
            {
                "id": "4",
                "name": "v1"
            }
        ],
        "versions": [],
        "parent": {
            "key": "TEST-2",
            "self": "https://jira.example/rest/api/2/issue/2",
            "fields": {}
        },
        "subtasks": [],
        "watches": {
            "watchCount": 0,
            "isWatching": false
        },
        "votes": {
            "votes": 0,
            "hasVoted": false
        },
        "progress": {
            "progress": 0,
            "total": 0
        },
        "aggregateprogress": {
            "progress": 0
        },
        "timetracking": {
            "timeSpentSeconds": 0
        },
        "security": {
            "id": "5",
            "name": "Internal"
        },
        "customfield_1": {
            "pluginData": [
                1,
                2
            ]
        }
    }
}
'@
            $issue = ConvertTo-JiraIssue -InputObject $wire -IncludeDebug
            $issue.IssueType.GetType() | Should -Be ([AtlassianPS.JiraPS.IssueType])
            $issue.Priority.GetType() | Should -Be ([AtlassianPS.JiraPS.Priority])
            $issue.Components.GetType() | Should -Be ([AtlassianPS.JiraPS.Component[]])
            $issue.FixVersions.GetType() | Should -Be ([AtlassianPS.JiraPS.Version[]])
            $issue.Worklog.Count | Should -Be 0
            $issue.Parent.Key | Should -Be 'TEST-2'
            $issue.Subtasks.Count | Should -Be 0
            $issue.Watches.WatchCount | Should -Be 0
            $issue.Votes.HasVoted | Should -BeFalse
            $issue.Progress.Total | Should -Be 0
            $issue.AggregateProgress.Progress | Should -Be 0
            $issue.TimeTracking.TimeSpentSeconds | Should -Be 0
            $issue.Security.GetType() | Should -Be ([AtlassianPS.JiraPS.IssueSecurityLevel])
            $issue.customfield_1.pluginData | Should -Be @(1, 2)
            $issue.Fields.customfield_1.pluginData | Should -Be @(1, 2)
            $issue.PSObject.Properties['priority'].MemberType | Should -Be 'Property'
            ($issue | ConvertTo-Json -Depth 20 | ConvertFrom-Json).FixVersions[0].Id | Should -Be '4'
        }

        It 'preserves empty, single and multiple nested collections (<count>)' -TestCases @(
            @{ count = 0 }
            @{ count = 1 }
            @{ count = 2 }
        ) {
            param($count)
            $values = @(
                for ($i = 0; $i -lt $count; $i++) {
                    [PSCustomObject]@{ id = "$i"; name = "item$i" }
                }
            )
            $wire = [PSCustomObject]@{
                key    = 'TEST-1'
                self   = 'https://jira.example/rest/api/2/issue/1'
                fields = [PSCustomObject]@{
                    components  = $values
                    fixVersions = $values
                    worklog     = [PSCustomObject]@{ worklogs = $values }
                }
            }
            $issue = ConvertTo-JiraIssue -InputObject $wire
            $issue.Components.GetType() | Should -Be ([AtlassianPS.JiraPS.Component[]])
            $issue.Components.Count | Should -Be $count
            $issue.FixVersions.GetType() | Should -Be ([AtlassianPS.JiraPS.Version[]])
            $issue.FixVersions.Count | Should -Be $count
            $issue.Worklog.GetType() | Should -Be ([AtlassianPS.JiraPS.Worklogitem[]])
            $issue.Worklog.Count | Should -Be $count
        }

        It 'returns concrete remote link details and preserves false status' {
            $linkResponse = ConvertFrom-Json @'
{
    "id": 1,
    "application": {
        "type": "wiki",
        "name": "Wiki"
    },
    "object": {
        "url": "https://example.com/",
        "title": "Page",
        "icon": {
            "url16x16": "https://example.com/icon.png"
        },
        "status": {
            "resolved": false,
            "icon": {
                "link": "https://example.com/status",
                "title": "Open"
            }
        }
    }
}
'@
            $link = ConvertTo-JiraLink -InputObject $linkResponse
            $link.Application.GetType() | Should -Be ([AtlassianPS.JiraPS.LinkApplication])
            $link.RemoteObject.GetType() | Should -Be ([AtlassianPS.JiraPS.RemoteLinkObject])
            $link.RemoteObject.Icon.GetType() | Should -Be ([AtlassianPS.JiraPS.RemoteLinkIcon])
            $link.RemoteObject.Status.GetType() | Should -Be ([AtlassianPS.JiraPS.RemoteLinkStatus])
            $link.RemoteObject.Status.Icon.GetType() | Should -Be ([AtlassianPS.JiraPS.RemoteLinkIcon])
            $link.RemoteObject.Status.Resolved | Should -BeFalse
            $empty = ConvertTo-JiraLink -InputObject (ConvertFrom-Json '{"id":2,"object":{"title":"Other"}}')
            $empty.RemoteObject.Icon | Should -BeNullOrEmpty
            $empty.RemoteObject.Status | Should -BeNullOrEmpty
        }

        It 'types visibility and entity envelopes while preserving arbitrary property values' {
            $commentResponse = ConvertFrom-Json @'
{
    "id": "1",
    "visibility": {
        "type": "group",
        "value": "members",
        "identifier": "g1"
    },
    "properties": [
        {
            "key": "plugin",
            "value": {
                "nested": [
                    1,
                    2
                ]
            }
        }
    ]
}
'@
            $comment = ConvertTo-JiraComment -InputObject $commentResponse
            $comment.Visibility.GetType() | Should -Be ([AtlassianPS.JiraPS.Visibility])
            $comment.Visibility.Identifier | Should -Be 'g1'
            $comment.Properties.GetType() | Should -Be ([AtlassianPS.JiraPS.EntityProperty[]])
            $comment.Properties[0].Value.nested | Should -Be @(1, 2)
            $worklog = ConvertTo-JiraWorklogitem -InputObject (ConvertFrom-Json '{"id":1,"visibility":{"type":"role","value":"Developers"}}')
            $worklog.Visibility.GetType() | Should -Be ([AtlassianPS.JiraPS.Visibility])
        }

        It 'types project maps, categories and assignee settings' {
            $projectResponse = ConvertFrom-Json @'
{
    "id": "1",
    "key": "TEST",
    "roles": {
        "Developers": "https://jira.example/role/1"
    },
    "projectCategory": {
        "id": "2",
        "name": "Public"
    },
    "assigneeType": "PROJECT_LEAD",
    "versions": [
        {
            "id": "1"
        }
    ]
}
'@
            $project = ConvertTo-JiraProject -InputObject $projectResponse
            $project.Roles.GetType() | Should -Be ([System.Collections.Generic.Dictionary[string, uri]])
            $project.Roles['Developers'] | Should -Be ([uri]'https://jira.example/role/1')
            $project.Category.GetType() | Should -Be ([AtlassianPS.JiraPS.ProjectCategory])
            $project.AssigneeType | Should -Be ([AtlassianPS.JiraPS.AssigneeType]::PROJECT_LEAD)
        }

        It 'types Cloud and Data Center project role actors' {
            $roleResponse = ConvertFrom-Json @'
{
    "actors": [
        {
            "type": "atlassian-user-role-actor",
            "actorUser": {
                "accountId": "cloud"
            }
        },
        {
            "type": "atlassian-group-role-actor",
            "actorGroup": {
                "name": "devs",
                "groupId": "g1"
            }
        },
        {
            "type": "atlassian-user-role-actor",
            "name": "dc-user"
        }
    ]
}
'@
            $role = ConvertTo-JiraProjectRole -InputObject $roleResponse
            $role.Actors.GetType() | Should -Be ([AtlassianPS.JiraPS.RoleActor[]])
            $role.Actors[0].Type | Should -Be ([AtlassianPS.JiraPS.ActorType]::AtlassianUserRoleActor)
            $role.Actors[0].ActorUser.AccountId | Should -Be 'cloud'
            $role.Actors[1].ActorGroup.Id | Should -Be 'g1'
            $role.Actors[2].Name | Should -Be 'dc-user'
        }

        It 'uses typed schemas and does not overwrite them with raw metadata' {
            $metaResponse = ConvertFrom-Json @'
{
    "fieldId": "customfield_1",
    "schema": {
        "type": "array",
        "items": "option",
        "customId": 1,
        "configuration": {
            "plugin": "value"
        }
    },
    "operations": [
        "set"
    ],
    "allowedValues": [
        {
            "id": "1",
            "plugin": "x"
        }
    ]
}
'@
            $meta = ConvertTo-JiraCreateMetaField -InputObject $metaResponse
            $meta.Schema.GetType() | Should -Be ([AtlassianPS.JiraPS.FieldSchema])
            $meta.Operations.GetType() | Should -Be ([string[]])
            $meta.Schema.Configuration['plugin'] | Should -Be 'value'
            $meta.AllowedValues[0].plugin | Should -Be 'x'
            $meta.PSObject.Properties['Schema'].MemberType | Should -Be 'Property'
        }

        It 'preserves typed edit metadata schemas and empty operations' {
            $edit = ConvertTo-JiraEditMetaField -InputObject (ConvertFrom-Json '{"fields":{"customfield_1":{"schema":{"type":"array"},"operations":[]}}}')
            $edit.Schema.GetType() | Should -Be ([AtlassianPS.JiraPS.FieldSchema])
            $edit.Operations.Count | Should -Be 0
        }

        It 'types filter sharing and subscription pages on <deployment>' -TestCases @(
            @{ deployment = 'Cloud'; user = @{ accountId = 'u1' } }
            @{ deployment = 'Data Center'; user = @{ name = 'u1' } }
        ) {
            param($user)
            $wire = [PSCustomObject]@{
                id               = '1'
                sharePermissions = @(
                    @{ id = 2; type = 'group'; group = @{ name = 'devs' } }
                )
                sharedUsers      = @{
                    size  = 1
                    items = @($user)
                }
                subscriptions    = @{
                    size          = 1
                    'max-results' = 50
                    items         = @(
                        @{ id = 1; user = $user }
                    )
                }
            }
            $filter = ConvertTo-JiraFilter -InputObject $wire
            $filter.SharePermission.GetType() | Should -Be ([AtlassianPS.JiraPS.FilterPermission[]])
            $filter.SharedUser.GetType() | Should -Be ([AtlassianPS.JiraPS.UserList])
            $filter.SharedUser.Items.GetType() | Should -Be ([AtlassianPS.JiraPS.User[]])
            $filter.SharedUser.Items.Count | Should -Be 1
            $filter.Subscription.Items.GetType() | Should -Be ([AtlassianPS.JiraPS.FilterSubscription[]])
            $filter.Subscription.Items[0].User.GetType() | Should -Be ([AtlassianPS.JiraPS.User])
            $updated = ConvertTo-JiraFilter -InputObject $filter -FilterPermissions (ConvertFrom-Json '[{"id":3,"type":"global"}]')
            $updated.Subscription.Items.Count | Should -Be 1
        }

        It 'handles omitted and empty filter pages without producing placeholder users' {
            $filter = ConvertTo-JiraFilter -InputObject (ConvertFrom-Json '{"id":"1","sharedUsers":{"size":0,"items":[]},"subscriptions":{"size":0,"items":[]}}')
            $filter.SharedUser.Items.Count | Should -Be 0
            $filter.Subscription.Items.Count | Should -Be 0
            $filter.SharePermission.Count | Should -Be 0
            $empty = ConvertTo-JiraFilter -InputObject (ConvertFrom-Json '{"id":"2"}')
            $empty.SharedUser | Should -BeNullOrEmpty
            $empty.Subscription | Should -BeNullOrEmpty
        }

        It 'types user avatars and tolerates unknown account types' {
            $user = ConvertTo-JiraUser -InputObject (ConvertFrom-Json '{"accountType":"unknown","avatarUrls":{"16x16":"https://jira.example/avatar.png"}}')
            $user.AccountType | Should -BeNullOrEmpty
            $user.AvatarUrl['16x16'] | Should -Be ([uri]'https://jira.example/avatar.png')
        }

        It 'types server auxiliary properties' {
            $infoResponse = ConvertFrom-Json @'
{
    "deploymentType": "Server",
    "serverTimeZone": {
        "id": "UTC",
        "displayName": "UTC"
    },
    "defaultLocale": {
        "locale": "en_US"
    }
}
'@
            $info = ConvertTo-JiraServerInfo -InputObject $infoResponse
            $info.ServerTimeZone.GetType() | Should -Be ([AtlassianPS.JiraPS.ServerTimeZone])
            $info.DefaultLocale.GetType() | Should -Be ([AtlassianPS.JiraPS.ServerLocale])
            $info.DeploymentType.GetType() | Should -Be ([AtlassianPS.JiraPS.DeploymentType])
        }
    }
}
