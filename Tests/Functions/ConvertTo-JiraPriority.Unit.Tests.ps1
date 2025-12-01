#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "ConvertTo-JiraPriority" -Tag 'Unit' {

    BeforeAll {
        . "$PSScriptRoot/../../Tests/Helpers/Resolve-ModuleSource.ps1"
        $moduleToTest = Resolve-ModuleSource
        Import-Module $moduleToTest -Force
    }
    AfterAll {
        Remove-Module JiraPS -ErrorAction SilentlyContinue
    }

    InModuleScope JiraPS {

        . "$PSScriptRoot/../Shared.ps1"

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
        $sampleObject = ConvertFrom-Json -InputObject $sampleJson

        $r = ConvertTo-JiraPriority -InputObject $sampleObject

        It "Creates a PSObject out of JSON input" {
            $r | Should -Not -BeNullOrEmpty
        }

        checkPsType $r 'JiraPS.Priority'

        defProp $r 'Id' $priorityId
        defProp $r 'Name' $priorityName
        defProp $r 'RestUrl' "$jiraServer/rest/api/2/priority/$priorityId"
        defProp $r 'Description' $priorityDescription
        defProp $r 'StatusColor' '#cc0000'
    }
}
