#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-Jira* roundtrip into AtlassianPS.JiraPS strong types" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            $script:server = 'https://jira.example.com'
        }

        Context "ConvertTo-JiraUser" {
            BeforeAll {
                $script:userJson = @"
{
    "self": "$script:server/rest/api/2/user?username=jdoe",
    "key": "jdoe",
    "name": "jdoe",
    "accountId": "5b10a2844c20165700ede21g",
    "displayName": "John Doe",
    "emailAddress": "jdoe@example.com",
    "active": true,
    "timeZone": "Etc/UTC",
    "locale": "en_US"
}
"@
                $script:userObj = ConvertTo-JiraUser -InputObject (ConvertFrom-Json $userJson)
            }

            It "returns AtlassianPS.JiraPS.User" {
                $script:userObj.GetType().FullName | Should -Be 'AtlassianPS.JiraPS.User'
                $script:userObj.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.User'
            }

            It "maps wire-payload fields onto class properties" {
                $script:userObj.Name | Should -Be 'jdoe'
                $script:userObj.AccountId | Should -Be '5b10a2844c20165700ede21g'
                $script:userObj.DisplayName | Should -Be 'John Doe'
                $script:userObj.EmailAddress | Should -Be 'jdoe@example.com'
                $script:userObj.Active | Should -BeTrue
            }
        }

        Context "ConvertTo-JiraProject" {
            BeforeAll {
                $script:projectJson = @"
{
    "self": "$script:server/rest/api/2/project/10000",
    "id": "10000",
    "key": "TEST",
    "name": "Test Project",
    "description": "A test project",
    "lead": {
        "self": "$script:server/rest/api/2/user?username=lead",
        "name": "lead",
        "key": "lead",
        "displayName": "Lead User",
        "active": true
    },
    "issueTypes": [],
    "roles": {},
    "components": [],
    "style": "next-gen",
    "projectCategory": {
        "id": "10000",
        "name": "Engineering"
    }
}
"@
                $script:projectObj = ConvertTo-JiraProject -InputObject (ConvertFrom-Json $projectJson)
            }

            It "returns AtlassianPS.JiraPS.Project with the legacy alias" {
                $script:projectObj.GetType().FullName | Should -Be 'AtlassianPS.JiraPS.Project'
                $script:projectObj.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.Project'
            }

            It "converts the lead into a strong-typed User" {
                $script:projectObj.Lead.GetType().FullName | Should -Be 'AtlassianPS.JiraPS.User'
                $script:projectObj.Lead.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.User'
            }

            It "preserves the projectCategory mapping" {
                $script:projectObj.Category.name | Should -Be 'Engineering'
            }
        }

        Context "ConvertTo-JiraVersion" {
            BeforeAll {
                $script:versionJson = @"
{
    "self": "$script:server/rest/api/2/version/10000",
    "id": "10000",
    "name": "1.0.0",
    "description": "First release",
    "archived": false,
    "released": true,
    "overdue": false,
    "projectId": 10000,
    "startDate": "2025-01-01",
    "releaseDate": "2025-02-01"
}
"@
                $script:versionObj = ConvertTo-JiraVersion -InputObject (ConvertFrom-Json $versionJson)
            }

            It "returns AtlassianPS.JiraPS.Version with the legacy alias" {
                $script:versionObj.GetType().FullName | Should -Be 'AtlassianPS.JiraPS.Version'
                $script:versionObj.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.Version'
            }

            It "parses dates into DateTime" {
                $script:versionObj.StartDate | Should -BeOfType [System.DateTime]
                $script:versionObj.ReleaseDate | Should -BeOfType [System.DateTime]
            }

            It "leaves StartDate and ReleaseDate null when the payload omits them" {
                $minimalJson = '{ "id": "1", "name": "minimal" }'
                $minimalVersion = ConvertTo-JiraVersion -InputObject (ConvertFrom-Json $minimalJson)
                $minimalVersion.StartDate | Should -BeNullOrEmpty
                $minimalVersion.ReleaseDate | Should -BeNullOrEmpty
            }
        }

        Context "ConvertTo-JiraComment" {
            BeforeAll {
                $script:commentJson = @"
{
    "self": "$script:server/rest/api/2/issue/10000/comment/100",
    "id": "100",
    "body": "Hello world",
    "author": { "name": "jdoe", "displayName": "John Doe" },
    "created": "2025-04-01T12:00:00.000+0000",
    "updated": "2025-04-02T13:00:00.000+0000"
}
"@
                $script:commentObj = ConvertTo-JiraComment -InputObject (ConvertFrom-Json $commentJson)
            }

            It "returns AtlassianPS.JiraPS.Comment with the legacy alias" {
                $script:commentObj.GetType().FullName | Should -Be 'AtlassianPS.JiraPS.Comment'
                $script:commentObj.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.Comment'
            }

            It "promotes the author to a strong-typed User" {
                $script:commentObj.Author.GetType().FullName | Should -Be 'AtlassianPS.JiraPS.User'
            }
        }

        Context "ConvertTo-JiraFilter" {
            BeforeAll {
                $script:filterJson = @"
{
    "self": "$script:server/rest/api/2/filter/100",
    "id": "100",
    "name": "Open Bugs",
    "jql": "project = TEST and issuetype = Bug",
    "favourite": true,
    "owner": { "name": "jdoe", "displayName": "John Doe" }
}
"@
                $script:filterObj = ConvertTo-JiraFilter -InputObject (ConvertFrom-Json $script:filterJson)
            }

            It "returns AtlassianPS.JiraPS.Filter with the legacy alias" {
                $script:filterObj.GetType().FullName | Should -Be 'AtlassianPS.JiraPS.Filter'
                $script:filterObj.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.Filter'
            }

            It "exposes 'Favorite' as an AliasProperty for 'Favourite'" {
                $member = $script:filterObj.PSObject.Members | Where-Object { $_.Name -eq 'Favorite' }
                $member.MemberType | Should -Be 'AliasProperty'
                $script:filterObj.Favorite | Should -Be $script:filterObj.Favourite
            }
        }

        Context "ConvertTo-JiraIssue (Cloud v3 shape)" {
            BeforeAll {
                $script:cloudIssueJson = @"
{
    "id": "10001",
    "key": "TEST-1",
    "self": "$script:server/rest/api/3/issue/10001",
    "fields": {
        "summary": "Cloud-shaped issue",
        "description": {
            "type": "doc",
            "version": 1,
            "content": [
                { "type": "paragraph", "content": [ { "type": "text", "text": "ADF description" } ] }
            ]
        },
        "creator":  { "self": "$script:server/rest/api/3/user?accountId=abc", "accountId": "abc", "displayName": "Creator User", "active": true },
        "reporter": { "self": "$script:server/rest/api/3/user?accountId=def", "accountId": "def", "displayName": "Reporter User", "active": true },
        "comment": {
            "comments": [
                {
                    "self": "$script:server/rest/api/3/issue/10001/comment/1",
                    "id": "1",
                    "author": { "accountId": "abc", "displayName": "Creator User" },
                    "body": { "type": "doc", "version": 1, "content": [ { "type": "paragraph", "content": [ { "type": "text", "text": "Only comment" } ] } ] },
                    "created": "2025-04-01T12:00:00.000+0000",
                    "updated": "2025-04-01T12:00:00.000+0000"
                }
            ],
            "total": 1
        }
    }
}
"@
                $script:cloudIssue = ConvertTo-JiraIssue -InputObject (ConvertFrom-Json $script:cloudIssueJson)
            }

            It "promotes Creator and Reporter to AtlassianPS.JiraPS.User" {
                $script:cloudIssue.Creator | Should -BeOfType [AtlassianPS.JiraPS.User]
                $script:cloudIssue.Reporter | Should -BeOfType [AtlassianPS.JiraPS.User]
            }

            It "flattens an ADF description into a string" {
                $script:cloudIssue.Description | Should -BeOfType [string]
                $script:cloudIssue.Description | Should -Be 'ADF description'
            }

            It "binds a single-comment payload as a Comment[] array" {
                # Regression guard for PowerShell single-element unwrap.
                $script:cloudIssue.Comment | Should -Not -BeNullOrEmpty
                $script:cloudIssue.Comment.GetType() | Should -Be ([AtlassianPS.JiraPS.Comment[]])
                $script:cloudIssue.Comment.Length | Should -Be 1
                $script:cloudIssue.Comment[0].Body | Should -Be 'Only comment'
            }
        }

        Context "ConvertTo-JiraServerInfo" {
            BeforeAll {
                $script:siJson = @"
{
    "baseUrl": "$script:server",
    "version": "1001.0.0",
    "deploymentType": "Cloud",
    "buildNumber": 1001,
    "buildDate": "2025-04-01T00:00:00.000+0000",
    "serverTime": "2025-04-23T12:00:00.000+0000",
    "serverTitle": "Cloud Jira"
}
"@
                $script:siObj = ConvertTo-JiraServerInfo -InputObject (ConvertFrom-Json $script:siJson)
            }

            It "returns AtlassianPS.JiraPS.ServerInfo with the legacy alias" {
                $script:siObj.GetType().FullName | Should -Be 'AtlassianPS.JiraPS.ServerInfo'
                $script:siObj.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.ServerInfo'
            }

            It "parses BuildDate into DateTime" {
                $script:siObj.BuildDate | Should -BeOfType [System.DateTime]
            }
        }
    }
}
