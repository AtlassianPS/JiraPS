$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {
    Describe "ConvertTo-JiraIssueLinkType" {
        function defProp($obj, $propName, $propValue)
        {
            It "Defines the '$propName' property" {
                $obj.$propName | Should Be $propValue
            }
        }

        $sampleJson = @'
{
  "issueLinkTypes": [
    {
      "id": "10000",
      "name": "Blocks",
      "inward": "is blocked by",
      "outward": "blocks",
      "self": "http://jira.example.com/rest/api/latest/issueLinkType/10000"
    },
    {
      "id": "10001",
      "name": "Cloners",
      "inward": "is cloned by",
      "outward": "clones",
      "self": "http://jira.example.com/rest/api/latest/issueLinkType/10001"
    },
    {
      "id": "10002",
      "name": "Duplicate",
      "inward": "is duplicated by",
      "outward": "duplicates",
      "self": "http://jira.example.com/rest/api/latest/issueLinkType/10002"
    },
    {
      "id": "10003",
      "name": "Relates",
      "inward": "relates to",
      "outward": "relates to",
      "self": "http://jira.example.com/rest/api/latest/issueLinkType/10003"
    }
  ]
}
'@
        $sampleObject = ConvertFrom-Json2 -InputObject $sampleJson |
            Select-Object -ExpandProperty issueLinkTypes

        Context 'Behavior testing' {
            $r = ConvertTo-JiraIssueLinkType -InputObject $sampleObject[0]
            It "Provides output" {
                $r | Should Not BeNullOrEmpty
            }

            It "Sets the type name to PSJira.issueLinkType" {
                ($r | Get-Member).TypeName | Should Be 'PSJira.issueLinkType'
            }

            defProp $r 'Id' '10000'
            defProp $r 'Name' 'Blocks'
            defProp $r 'InwardText' 'is blocked by'
            defProp $r 'OutwardText' 'blocks'
            defProp $r 'RestUrl' 'http://jira.example.com/rest/api/latest/issueLinkType/10000'

            It "Provides an array of objects if an array is passed" {
                $r2 = ConvertTo-JiraIssueLinkType -InputObject $sampleObject
                $r2.Count | Should Be 4
                $r2[0].Id | Should Be '10000'
                $r2[1].Id | Should Be '10001'
                $r2[2].Id | Should Be '10002'
                $r2[3].Id | Should Be '10003'
            }

            It "Handles pipeline input" {
                $r = $sampleObject | ConvertTo-JiraIssueLinkType
                $r.Count | Should Be 4
            }
        }
    }
}
