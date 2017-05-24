$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {

    $jiraServer = 'http://jiraserver.example.com'

    $projectKey = 'TEST'
    $projectId = '10004'

    $componentId = '10001'
    $componentName = 'Component 1'
    $componentId2 = '10002'
    $componentName2 = 'Component 2'


    $restResultAll = @"
[
  {
    "self": "$jiraServer/rest/api/2/component/$componentId",
    "id": "$componentId",
    "name": "$componentName",
    "project": "$projectKey",
    "projectId": "$projectId"
  },
  {
    "self": "$jiraServer/rest/api/2/component/$componentId2",
    "id": "$componentId2",
    "name": "$componentName2",
    "project": "$projectKey",
    "projectId": "$projectId"
  }
]
"@

    $restResultOne = @"
[
  {
    "self": "$jiraServer/rest/api/2/component/$componentId",
    "id": "$componentId",
    "name": "$componentName",
    "project": "$projectKey",
    "projectId": "$projectId"
  }
]
"@

    Describe "Get-JiraComponent" {
        Mock Get-JiraConfigServer -ModuleName PSJira {
            Write-Output $jiraServer
        }

        Mock Invoke-JiraMethod -ModuleName PSJira -ParameterFilter {$Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/latest/component/${componentId}"} {
            ConvertFrom-Json2 $restResultOne
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

        It "Returns details about specific components if the component ID is supplied" {
            $oneResult = Get-JiraComponent -Id $componentId
            $oneResult | Should Not BeNullOrEmpty
            @($oneResult).Count | Should Be 1
            $oneResult.Id | Should Be $componentId
        }

        It "Provides the Id of the component" {
            $oneResult = Get-JiraComponent -Id $componentId
            $oneResult.Id | Should Be $componentId
        }


    }
}


