$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {
    Describe "ConvertTo-JiraProject" {
        function defProp($obj, $propName, $propValue)
        {
            It "Defines the '$propName' property" {
                $obj.$propName | Should Be $propValue
            }
        }

        $jiraServer = 'http://jiraserver.example.com'

        $projectKey = 'IT'
        $projectId = '10003'
        $projectName = 'Information Technology'

        $sampleJson = @"
{
"self": "$jiraServer/rest/api/2/project/$projectId",
"id": "$projectId",
"key": "$projectKey",
"name": "$projectName",
"projectCategory": {
    "self": "$jiraServer/rest/api/2/projectCategory/10000",
    "id": "10000",
    "description": "All Project Catagories",
    "name": "All Project"
},
"components": {
    "self": "$jiraServer/rest/api/2/component/11000",
    "id": "11000",
    "description": "A test component",
    "name": "test component"
}
}
"@
        $sampleObject = ConvertFrom-Json2 -InputObject $sampleJson

        $r = ConvertTo-JiraProject -InputObject $sampleObject

        It "Creates a PSObject out of JSON input" {
            $r | Should Not BeNullOrEmpty
        }

        It "Sets the type name to PSJira.Project" {
            $r | Test-HasTypeName 'PSJira.Project' | Should Be $True
         }

        defProp $r 'Id' $projectId
        defProp $r 'Key' $projectKey
        defProp $r 'Name' $projectName
        defProp $r 'RestUrl' "$jiraServer/rest/api/2/project/$projectId"
    }
}
 