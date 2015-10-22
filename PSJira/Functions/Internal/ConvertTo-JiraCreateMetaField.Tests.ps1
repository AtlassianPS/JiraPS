$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

Describe "ConvertTo-JiraCreateMetaField" {
    function defProp($obj, $propName, $propValue)
    {
        It "Defines the '$propName' property" {
            $obj.$propName | Should Be $propValue
        }
    }

    $sampleJson = @'
{
    "required": true,
    "schema": {
        "type": "string",
        "system": "summary"
    },
    "name": "Summary",
    "hasDefaultValue": false,
    "operations": [
        "set"
    ],
    "fakeProperty": "Cool stuff"
}
'@
    $sampleObject = ConvertFrom-Json -InputObject $sampleJson

    $r = ConvertTo-JiraCreateMetaField $sampleObject
    It "Creates a PSObject out of JSON input" {
        $r | Should Not BeNullOrEmpty
    }

    It "Sets the type name to PSJira.CreateMetaField" {
        (Get-Member -InputObject $r).TypeName | Should Be 'PSJira.CreateMetaField'
    }

    defProp $r 'Name' 'Summary'
    defProp $r 'HasDefaultValue' $false

    # This one tests the "return everything available" functionality
    defProp $r 'fakeProperty' 'Cool stuff'
}
