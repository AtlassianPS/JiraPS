Describe "ConvertTo-JiraPriority" {

    Import-Module "$PSScriptRoot/../JiraPS" -Force -ErrorAction Stop

    InModuleScope JiraPS {

        . "$PSScriptRoot/Shared.ps1"

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

        checkPsType $r 'JiraPS.Priority'

        defProp $r 'Id' $priorityId
        defProp $r 'Name' $priorityName
        defProp $r 'RestUrl' "$jiraServer/rest/api/2/priority/$priorityId"
        defProp $r 'Description' $priorityDescription
        defProp $r 'StatusColor' '#cc0000'
    }
}
