#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

# Import module at script level for Pester v5 InModuleScope compatibility
. "$PSScriptRoot/../../Tests/Helpers/Resolve-ModuleSource.ps1"
$moduleToTest = Resolve-ModuleSource
Import-Module $moduleToTest -Force

Describe "ConvertTo-JiraField" -Tag 'Unit' {
    AfterAll {
        Remove-Module JiraPS -ErrorAction SilentlyContinue
    }

    InModuleScope JiraPS {

        . "$PSScriptRoot/../Shared.ps1"

        $sampleJson = '{"id":"issuetype","name":"Issue Type","custom":false,"orderable":true,"navigable":true,"searchable":true,"clauseNames":["issuetype","type"],"schema":{"type":"issuetype","system":"issuetype"}}'
        $sampleObject = ConvertFrom-Json -InputObject $sampleJson

        $r = ConvertTo-JiraField $sampleObject
        It "Creates a PSObject out of JSON input" {
            $r | Should -Not -BeNullOrEmpty
        }

        checkPsType $r 'JiraPS.Field'

        defProp $r 'Id' 'issuetype'
        defProp $r 'Name' 'Issue Type'
        defProp $r 'Custom' $false
    }
}
