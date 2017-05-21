[System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
$SuppressImportModule = $true
. $PSScriptRoot\Shared.ps1

Describe "ConvertFrom-Json2" {
	$sampleJson = '{"id":"issuetype","name":"Issue Type","custom":false,"orderable":true,"navigable":true,"searchable":true,"clauseNames":["issuetype","type"],"schema":{"type":"issuetype","system":"issuetype"}}'
    $sampleObject = ConvertFrom-Json2 -InputObject $sampleJson

	It "Creates a PSObject out of JSON input" {
        $sampleObject | Should Not BeNullOrEmpty
    }

	defProp $sampleObject 'Id' 'issuetype'
    defProp $sampleObject 'Name' 'Issue Type'
    defProp $sampleObject 'Custom' $false
}
