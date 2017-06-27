. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    $jiraServer = 'http://jiraserver.example.com'

    $issueTypeId = 2
    $issueTypeName = 'Desktop Support'

    $restResult = @"
[
    {
        "self": "$jiraServer/rest/api/latest/issuetype/12",
        "id": "12",
        "description": "This issue type is no longer used.",
        "iconUrl": "$jiraServer/images/icons/issuetypes/delete.png",
        "name": "ZZ_DO_NOT_USE",
        "subtask": false
    },
    {
        "self": "$jiraServer/rest/api/latest/issuetype/11",
        "id": "11",
        "description": "An issue related to classroom technology, moodle, library services",
        "iconUrl": "$jiraServer/images/icons/issuetypes/documentation.png",
        "name": "Educational Technology Services",
        "subtask": false
    },
    {
        "self": "$jiraServer/rest/api/latest/issuetype/4",
        "id": "4",
        "description": "An issue related to network connectivity or infrastructure including Access Control.",
        "iconUrl": "$jiraServer/images/icons/issuetypes/improvement.png",
        "name": "Network Services",
        "subtask": false
    },
    {
        "self": "$jiraServer/rest/api/latest/issuetype/6",
        "id": "6",
        "description": "An issue related to telephone services",
        "iconUrl": "$jiraServer/images/icons/issuetypes/genericissue.png",
        "name": "Telephone Services",
        "subtask": false
    },
    {
        "self": "$jiraServer/rest/api/latest/issuetype/8",
        "id": "8",
        "description": "An issue related to A/V and media services including teacher stations",
        "iconUrl": "$jiraServer/images/icons/issuetypes/genericissue.png",
        "name": "A/V-Media Services",
        "subtask": false
    },
    {
        "self": "$jiraServer/rest/api/latest/issuetype/1",
        "id": "1",
        "description": "An issue related to Banner, MU Online, Oracle Reports, MU Account Suite, Hobsons, or CS Gold",
        "iconUrl": "$jiraServer/images/icons/issuetypes/bug.png",
        "name": "Administrative System",
        "subtask": false
    },
    {
        "self": "$jiraServer/rest/api/latest/issuetype/10",
        "id": "10",
        "description": "The sub-task of the issue",
        "iconUrl": "$jiraServer/images/icons/issuetypes/subtask_alternate.png",
        "name": "Sub-task",
        "subtask": true
    },
    {
        "self": "$jiraServer/rest/api/latest/issuetype/2",
        "id": "2",
        "description": "An issue related to end-user workstations.",
        "iconUrl": "$jiraServer/images/icons/issuetypes/newfeature.png",
        "name": "Desktop Support",
        "subtask": false
    }
]
"@

    Describe "Get-JiraIssueType" {

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $Uri -eq "$jiraServer/rest/api/latest/issuetype"} {
            ConvertFrom-Json2 $restResult
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

        It "Gets all issue types in Jira if called with no parameters" {
            $allResults = Get-JiraIssueType
            $allResults | Should Not BeNullOrEmpty
            @($allResults).Count | Should Be 8
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -Scope It
        }

        It "Gets a specified issue type if an issue type ID is provided" {
            $oneResult = Get-JiraIssueType -IssueType $issueTypeId
            $oneResult | Should Not BeNullOrEmpty
            $oneResult.ID | Should Be $issueTypeId
            $oneResult.Name | Should Be $issueTypeName
        }

        It "Gets a specified issue type if an issue type name is provided" {
            $oneResult = Get-JiraIssueType -IssueType $issueTypeName
            $oneResult | Should Not BeNullOrEmpty
            $oneResult.ID | Should Be $issueTypeId
            $oneResult.Name | Should Be $issueTypeName
        }

        It "Handles positional parameters correctly" {
            $oneResult = Get-JiraIssueType 'Desktop Support'
            $oneResult | Should Not BeNullOrEmpty
            $oneResult.ID | Should Be 2
            $oneResult.Name | Should Be 'Desktop Support'
        }

        Context "Output Checking" {

            Mock ConvertTo-JiraIssueType {}

            Get-JiraIssueType

            It "Uses ConvertTo-JiraIssueType to beautify output" {
                Assert-MockCalled 'ConvertTo-JiraIssueType'
            }
        }
    }
}
