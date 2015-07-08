$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

Describe "ConvertTo-JiraField" {
    function defProp($obj, $propName, $propValue)
    {
        It "Defines the '$propName' property" {
            $obj.$propName | Should Be $propValue
        }
    }

    $sampleJson = '{"id":"issuetype","name":"Issue Type","custom":false,"orderable":true,"navigable":true,"searchable":true,"clauseNames":["issuetype","type"],"schema":{"type":"issuetype","system":"issuetype"}}'
    $sampleObject = ConvertFrom-Json -InputObject $sampleJson

    $r = ConvertTo-JiraField $sampleObject 
    It "Creates a PSObject out of JSON input" {
        $r | Should Not BeNullOrEmpty
    }
    
    It "Sets the type name to PSJira.Field" {
        (Get-Member -InputObject $r).TypeName | Should Be 'PSJira.Field'
    }

    defProp $r 'Id' 'issuetype'
    defProp $r 'Name' 'Issue Type'
    defProp $r 'Custom' $false
}
