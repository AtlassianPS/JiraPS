$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    $jiraServer = 'http://jiraserver.example.com'

    $projectKey = 'IT'
    $projectId = '10003'
    $projectName = 'Information Technology'

    $projectKey2 = 'TEST'
    $projectId2 = '10004'
    $projectName2 = 'Test Project'

    $restResultAll = @"
[
  {
    "self": "$jiraServer/rest/api/2/project/10003",
    "id": "$projectId",
    "key": "$projectKey",
    "name": "$projectName",
    "projectCategory": {
      "self": "$jiraServer/rest/api/2/projectCategory/10000",
      "id": "10000",
      "description": "All Project Catagories",
      "name": "All Project"
    }
  },
  {
    "self": "$jiraServer/rest/api/2/project/10121",
    "id": "$projectId2",
    "key": "$projectKey2",
    "name": "$projectName2",
    "projectCategory": {
      "self": "$jiraServer/rest/api/2/projectCategory/10000",
      "id": "10000",
      "description": "All Project Catagories",
      "name": "All Project"
    }
  }
]
"@

    $restResultOne = @"
[
  {
    "self": "$jiraServer/rest/api/2/project/10003",
    "id": "$projectId",
    "key": "$projectKey",
    "name": "$projectName",
    "projectCategory": {
      "self": "$jiraServer/rest/api/2/projectCategory/10000",
      "id": "10000",
      "description": "All Project Catagories",
      "name": "All Project"
    }
  }
]
"@

    Describe "Get-JiraProject" {
        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/latest/project"} {
            ConvertFrom-Json $restResultAll
        }

        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/latest/project/${projectKey}?expand=projectKeys"} {
            ConvertFrom-Json $restResultOne
        }

        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/latest/project/${projectId}?expand=projectKeys"} {
            ConvertFrom-Json $restResultOne
        }

        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/latest/project/${projectKey}expand=projectKeys"} {
            ConvertFrom-Json $restResultOne
        }

        # Generic catch-all. This will throw an exception if we forgot to mock something.
        Mock Invoke-JiraMethod -ModuleName PSJira {
            Write-Host "       Mocked Invoke-JiraMethod with no parameter filter." -ForegroundColor DarkRed
            Write-Host "         [Method]         $Method" -ForegroundColor DarkRed
            Write-Host "         [URI]            $URI" -ForegroundColor DarkRed
            throw "Unidentified call to Invoke-JiraMethod"
        }

#        Mock Write-Debug {
#            Write-Host "DEBUG: $Message" -ForegroundColor Yellow
#        }

        #############
        # Tests
        #############

        It "Returns all projects if called with no parameters" {
            $allResults = Get-JiraProject
            $allResults | Should Not BeNullOrEmpty
            @($allResults).Count | Should Be (ConvertFrom-Json -InputObject $restResultAll).Count
        }

        It "Returns details about specific projects if the project key is supplied" {
            $oneResult = Get-JiraProject -Project $projectKey
            $oneResult | Should Not BeNullOrEmpty
            @($oneResult).Count | Should Be 1
        }

        It "Returns details about specific projects if the project ID is supplied" {
            $oneResult = Get-JiraProject -Project $projectId
            $oneResult | Should Not BeNullOrEmpty
            @($oneResult).Count | Should Be 1
        }

        It "Provides the key of the project" {
            $oneResult = Get-JiraProject -Project $projectKey
            $oneResult.Key | Should Be $projectKey
        }

        It "Provides the ID of the project" {
            $oneResult = Get-JiraProject -Project $projectKey
            $oneResult.Id | Should Be $projectId
        }
    }
}


