$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {
    Describe "ConvertTo-JiraPriority" {
        function defProp($obj, $propName, $propValue)
        {
            It "Defines the '$propName' property" {
                $obj.$propName | Should Be $propValue
            }
        }

        $jiraServer = 'http://jiraserver.example.com'

        $priorityId = 1
        $priorityName = 'Critical'
        $priorityDescription = 'Cannot contine normal operations'

        $sampleJson = @"
{
    "self": "$jiraServer/rest/api/2/priority/1",
    "statusColor": "#cc0000",
    "description": "$priorityDescription",
    "name": "$priorityName",
    "id": "$priorityId"
  }
"@
        $sampleObject = ConvertFrom-Json2 -InputObject $sampleJson

        $r = ConvertTo-JiraPriority -InputObject $sampleObject

        It "Creates a PSObject out of JSON input" {
            $r | Should Not BeNullOrEmpty
        }

        It "Sets the type name to PSJira.Priority" {
            $r | Test-HasTypeName 'PSJira.Priority' | Should Be $True
        }

        defProp $r 'Id' $priorityId
        defProp $r 'Name' $priorityName
        defProp $r 'RestUrl' "$jiraServer/rest/api/2/priority/$priorityId"
        defProp $r 'Description' $priorityDescription
        defProp $r 'StatusColor' '#cc0000'
    }
}
