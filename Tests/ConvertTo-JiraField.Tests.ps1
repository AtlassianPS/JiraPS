. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    Describe "ConvertTo-JiraField" {

        $sampleJson = '{"id":"issuetype","name":"Issue Type","custom":false,"orderable":true,"navigable":true,"searchable":true,"clauseNames":["issuetype","type"],"schema":{"type":"issuetype","system":"issuetype"}}'
        $sampleObject = ConvertFrom-Json2 -InputObject $sampleJson

        $r = ConvertTo-JiraField $sampleObject
        It "Creates a PSObject out of JSON input" {
            $r | Should Not BeNullOrEmpty
        }

        checkPsType $r 'JiraPS.Field'

        defProp $r 'Id' 'issuetype'
        defProp $r 'Name' 'Issue Type'
        defProp $r 'Custom' $false
    }
}
