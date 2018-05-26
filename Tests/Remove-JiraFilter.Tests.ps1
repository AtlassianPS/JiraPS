Describe 'Get-JiraFilter' {
    BeforeAll {
        Remove-Module JiraPS
        Import-Module "$PSScriptRoot/../JiraPS" -Force -ErrorAction Stop
    }

    InModuleScope JiraPS {

        . "$PSScriptRoot/Shared.ps1"

        #region Definitions
        $jiraServer = "https://jira.example.com"

        $responseFilter = @"
{
    "self": "$jiraServer/rest/api/latest/filter/12844",
    "id": "12844",
    "name": "All JIRA Bugs",
    "owner": {
        "self": "$jiraServer/rest/api/2/user?username=scott@atlassian.com",
        "key": "scott@atlassian.com",
        "name": "scott@atlassian.com",
        "avatarUrls": {
            "16x16": "$jiraServer/secure/useravatar?size=xsmall&avatarId=10612",
            "24x24": "$jiraServer/secure/useravatar?size=small&avatarId=10612",
            "32x32": "$jiraServer/secure/useravatar?size=medium&avatarId=10612",
            "48x48": "$jiraServer/secure/useravatar?avatarId=10612"
        },
        "displayName": "Scott Farquhar [Atlassian]",
        "active": true
    },
    "jql": "project = 10240 AND issuetype = 1 ORDER BY key DESC",
    "viewUrl": "$jiraServer/secure/IssueNavigator.jspa?mode=hide&requestId=12844",
    "searchUrl": "$jiraServer/rest/api/latest/search?jql=project+%3D+10240+AND+issuetype+%3D+1+ORDER+BY+key+DESC",
    "favourite": false,
    "sharePermissions": [
        {
            "id": 10049,
            "type": "global"
        }
    ],
    "sharedUsers": {
        "size": 0,
        "items": [],
        "max-results": 1000,
        "start-index": 0,
        "end-index": 0
    },
    "subscriptions": {
        "size": 0,
        "items": [],
        "max-results": 1000,
        "start-index": 0,
        "end-index": 0
    }
}
"@
        #endregion Definitions

        #region Mocks
        Mock Get-JiraConfigServer -ModuleName JiraPS {
            $jiraServer
        }

        Mock ConvertTo-JiraFilter -ModuleName JiraPS {
            foreach ($i in $InputObject) {
                $i.PSObject.TypeNames.Insert(0, 'JiraPS.Filter')
                $i | Add-Member -MemberType AliasProperty -Name 'RestURL' -Value 'self'
                $i
            }
        }

        Mock Get-JiraFilter -ModuleName JiraPS {
            foreach ($i in $Id) {
                ConvertTo-JiraFilter (ConvertFrom-Json $responseFilter)
            }
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Delete' -and $URI -like "$jiraServer/rest/api/*/filter/*"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $responseFilter
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }
        #endregion Mocks

        Context "Sanity checking" {
            $command = Get-Command -Name Get-JiraFilter

            defParam $command 'InputObject'
            defParam $command 'Credential'
        }

        Context "Behavior testing" {
            It "Invokes the Jira API to delete a filter" {
                 Get-JiraFilter -Id 12844 | Remove-JiraFilter #} | Should Not Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {$Method -eq 'Delete' -and $URI -like '*/rest/api/*/filter/12844'}
            }
        }

        Context "Input testing" {
            It "Accepts a filter object for the -InputObject parameter" {
                { Remove-JiraFilter -InputObject (Get-JiraFilter "12345") } | Should Not Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "Accepts a filter object without the -InputObject parameter" {
                { Remove-JiraFilter (Get-JiraFilter "12345") } | Should Not Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "Accepts multiple filter objects to the -Filter parameter" {
                { Remove-JiraFilter -InputObject (Get-JiraFilter 12345,12345) } | Should Not Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -Scope It
            }

            It "Accepts a JiraPS.Filter object via pipeline" {
                { Get-JiraFilter 12345,12345 | Remove-JiraFilter } | Should Not Throw

                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 2 -Scope It
            }

            It "fails if something other than [JiraPS.Filter] is provided" {
                { "12345" | Remove-JiraFilter -ErrorAction Stop } | Should Throw
                { Remove-JiraFilter "12345" -ErrorAction Stop} | Should Throw
            }
        }
    }
}
