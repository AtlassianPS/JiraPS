Describe 'Get-JiraFilter' {

    Import-Module "$PSScriptRoot/../JiraPS" -Force -ErrorAction Stop

    InModuleScope JiraPS {

        . "$PSScriptRoot/Shared.ps1"

        $jiraServer = "https://jira.example.com"

        $response = @'
{
    "self": "https://jira.atlassian.com/rest/api/latest/filter/12844",
    "id": "12844",
    "name": "All JIRA Bugs",
    "owner": {
        "self": "https://jira.atlassian.com/rest/api/2/user?username=scott@atlassian.com",
        "key": "scott@atlassian.com",
        "name": "scott@atlassian.com",
        "avatarUrls": {
            "16x16": "https://jira.atlassian.com/secure/useravatar?size=xsmall&avatarId=10612",
            "24x24": "https://jira.atlassian.com/secure/useravatar?size=small&avatarId=10612",
            "32x32": "https://jira.atlassian.com/secure/useravatar?size=medium&avatarId=10612",
            "48x48": "https://jira.atlassian.com/secure/useravatar?avatarId=10612"
        },
        "displayName": "Scott Farquhar [Atlassian]",
        "active": true
    },
    "jql": "project = 10240 AND issuetype = 1 ORDER BY key DESC",
    "viewUrl": "https://jira.atlassian.com/secure/IssueNavigator.jspa?mode=hide&requestId=12844",
    "searchUrl": "https://jira.atlassian.com/rest/api/latest/search?jql=project+%3D+10240+AND+issuetype+%3D+1+ORDER+BY+key+DESC",
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
'@

        Mock Get-JiraConfigServer {
            $jiraServer
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/latest/filter/12345"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $response
        }
        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/latest/filter/67890"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $response
        }
        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -like "$jiraServer/rest/api/latest/filter/*"} {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            ConvertFrom-Json $response
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        Context "Sanity checking" {
            $command = Get-Command -Name Get-JiraFilter

            defParam $command 'Id'
            defParam $command 'InputObject'
            defParam $command 'Credential'
        }

        Context "Behavior testing" {
            It "Queries JIRA for a filter with a given ID" {
                { Get-JiraFilter -Id 12345 } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {$Method -eq 'Get' -and $URI -like '*/rest/api/*/filter/12345'}
            }

            It "Uses ConvertTo-JiraFilter to output a Filter object if JIRA returns data" {
                Mock Invoke-JiraMethod -ModuleName JiraPS { $true }
                Mock ConvertTo-JiraFilter -ModuleName JiraPS {}
                { Get-JiraFilter -Id 12345 } | Should Not Throw
                Assert-MockCalled -CommandName ConvertTo-JiraFilter -ModuleName JiraPS
            }
        }

        Context "Input testing" {
            $sampleFilter = ConvertTo-JiraFilter ( ConvertFrom-Json $response )

            It "Accepts a filter ID for the -Filter parameter" {
                { Get-JiraFilter -Id 12345 } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
            }

            It "Accepts multiple filter IDs to the -Filter parameter" {
                { Get-JiraFilter -Id '12345', '67890' } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {$Method -eq 'Get' -and $URI -like '*/rest/api/*/filter/12345'}
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {$Method -eq 'Get' -and $URI -like '*/rest/api/*/filter/67890'}
            }

            It "Accepts a JiraPS.Filter object to the InputObject parameter" {
                { Get-JiraFilter -InputObject $sampleFilter } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {$Method -eq 'Get' -and $URI -like '*rest/api/*/filter/12844'}
            }

            It "Accepts a JiraPS.Filter object via pipeline" {
                { $sampleFilter | Get-JiraFilter } | Should Not Throw
                Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It -ParameterFilter {$Method -eq 'Get' -and $URI -like '*rest/api/*/filter/12844'}
            }
        }
    }
}
