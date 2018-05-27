Describe "Get-JiraPriority" {

    Import-Module "$PSScriptRoot/../JiraPS" -Force -ErrorAction Stop

    InModuleScope JiraPS {

        . "$PSScriptRoot/Shared.ps1"

        $jiraServer = 'http://jiraserver.example.com'

        $restResultAll = @"
[
    {
        "self": "$jiraServer/rest/api/2/priority/1",
        "statusColor": "#cc0000",
        "description": "Cannot continue work. Affects teaching and learning",
        "name": "Critical",
        "id": "1"
    },
    {
        "self": "$jiraServer/rest/api/2/priority/2",
        "statusColor": "#ff0000",
        "description": "High priority, attention needed immediately",
        "name": "High",
        "id": "2"
    },
    {
        "self": "$jiraServer/rest/api/2/priority/3",
        "statusColor": "#ffff66",
        "description": "Typical request for information or service",
        "name": "Normal",
        "id": "3"
    },
    {
        "self": "$jiraServer/rest/api/2/priority/4",
        "statusColor": "#006600",
        "description": "Upcoming project, planned request",
        "name": "Project",
        "id": "4"
    },
    {
        "self": "$jiraServer/rest/api/2/priority/5",
        "statusColor": "#0000ff",
        "description": "General questions, request for enhancement, wish list",
        "name": "Low",
        "id": "5"
    }
]
"@

        $restResultOne = @"
{
    "self": "$jiraServer/rest/api/2/priority/1",
    "statusColor": "#cc0000",
    "description": "Cannot continue work. Affects teaching and learning",
    "name": "Critical",
    "id": "1"
}
"@

        Mock Get-JiraConfigServer -ModuleName JiraPS {
            Write-Output $jiraServer
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/latest/priority"} {
            ConvertFrom-Json $restResultAll
        }

        Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/latest/priority/1"} {
            ConvertFrom-Json $restResultOne
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName JiraPS {
            ShowMockInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            throw "Unidentified call to Invoke-JiraMethod"
        }

        #############
        # Tests
        #############

        It "Gets all available priorities if called with no parameters" {
            $getResult = Get-JiraPriority -Credential $testCred
            $getResult | Should Not BeNullOrEmpty
            $getResult.Count | Should Be 5
        }

        It "Gets one priority if the ID parameter is supplied" {
            $getResult = Get-JiraPriority -Id 1 -Credential $testCred
            $getResult | Should Not BeNullOrEmpty
            @($getResult).Count | Should Be 1
        }

        It "Converts the output object to type JiraPS.Priority" {
            $getResult = Get-JiraPriority -Id 1 -Credential $testCred
            $getResult | Should Not BeNullOrEmpty
            checkType $getResult "JiraPS.Priority"
        }
    }
}
