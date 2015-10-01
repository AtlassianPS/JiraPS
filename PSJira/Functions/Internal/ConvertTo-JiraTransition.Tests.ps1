$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {
    Describe "ConvertTo-JiraTransition" {
        function defProp($obj, $propName, $propValue)
        {
            It "Defines the '$propName' property" {
                $obj.$propName | Should Be $propValue
            }
        }

        $jiraServer = 'http://jiraserver.example.com'

        $tId = 11
        $tName = 'Start Progress'

        # Transition result status
        $tRId = 3
        $tRName = 'In Progress'
        $tRDesc = 'This issue is being actively worked on at the moment by the assignee.'

        $sampleJson = @"
{
    "id": "$tId",
    "name": "$tName",
    "to": {
    "self": "$jiraServer/rest/api/2/status/$tRId",
    "description": "$tRDesc",
    "iconUrl": "$jiraServer/images/icons/statuses/inprogress.png",
    "name": "$tRName",
    "id": "$tRId",
    "statusCategory": {
        "self": "$jiraServer/rest/api/2/statuscategory/4",
        "id": 4,
        "key": "indeterminate",
        "colorName": "yellow",
        "name": "In Progress"
    }
    }
}
"@
        $sampleObject = ConvertFrom-Json -InputObject $sampleJson

        $r = ConvertTo-JiraTransition -InputObject $sampleObject

        It "Creates a PSObject out of JSON input" {
            $r | Should Not BeNullOrEmpty
        }

        It "Sets the type name to PSJira.Transition" {
            (Get-Member -InputObject $r).TypeName | Should Be 'PSJira.Transition'
        }

        defProp $r 'Id' $tId
        defProp $r 'Name' $tName

        It "Defines the 'ResultStatus' property as a PSJira.Status object" {
            $r.ResultStatus.Id | Should Be $tRId
            $r.ResultStatus.Name | Should Be $tRName
        }
    }
}


