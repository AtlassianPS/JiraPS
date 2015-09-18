$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    $jiraServer = 'http://jiraserver.example.com'

    # In my Jira instance, this returns 34 objects. I've stripped it down quite a bit for testing.
    $restResult = @"
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

    Describe "Get-JiraField" {
        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Get' -and $Uri -eq "$jiraServer/rest/api/latest/field"} {
            ConvertFrom-Json $restResult
        }

        It "Gets all fields in Jira if called with no parameters" {
            $allResults = Get-JiraField
            $allResults | Should Not BeNullOrEmpty
            @($allResults).Count | Should Be @((ConvertFrom-Json -InputObject $restResult)).Count
            Assert-MockCalled -CommandName Invoke-JiraMethod -ModuleName PSJira -Exactly -Times 1 -Scope It
        }

        It "Gets a specified field if a field ID is provided" {
            $oneResult = Get-JiraField -Field issuetype
            $oneResult | Should Not BeNullOrEmpty
            $oneResult.ID | Should Be 'issuetype'
            $oneResult.Name | Should Be 'Issue Type'
        }

        It "Gets a specified issue type if an issue type name is provided" {
            $oneResult = Get-JiraField -Field 'Issue Type'
            $oneResult | Should Not BeNullOrEmpty
            $oneResult.ID | Should Be 'issuetype'
            $oneResult.Name | Should Be 'Issue Type'
        }

        It "Handles positional parameters correctly" {
            $oneResult = Get-JiraField 'Issue Type'
            $oneResult | Should Not BeNullOrEmpty
            $oneResult.ID | Should Be issuetype
            $oneResult.Name | Should Be 'Issue Type'
        }

        It "Returns output of type PSJira.Field" {
            $oneResult = Get-JiraField -Field 'Issue Type'
            (Get-Member -InputObject $oneResult).TypeName | Should Be 'PSJira.Field'
        }
    }
}


