
. $PSScriptRoot\Shared.ps1

InModuleScope PSJira {
    Describe "ConvertTo-JiraEditMetaField" {
        . $PSScriptRoot\Shared.ps1

        $sampleJson = @'
{
  "fields": {
    "summary": {
      "required": true,
      "schema": {
        "type": "string",
        "system": "summary"
      },
      "name": "Summary",
      "hasDefaultValue": false,
      "operations": [
        "set"
      ]
    },
    "priority": {
      "required": false,
      "schema": {
        "type": "priority",
        "system": "priority"
      },
      "name": "Priority",
      "hasDefaultValue": true,
      "operations": [
        "set"
      ],
      "allowedValues": [
        {
          "self": "http://jiraserver.example.com/rest/api/2/priority/1",
          "iconUrl": "http://jiraserver.example.com/images/icons/priorities/blocker.png",
          "name": "Block",
          "id": "1"
        },
        {
          "self": "http://jiraserver.example.com/rest/api/2/priority/2",
          "iconUrl": "http://jiraserver.example.com/images/icons/priorities/critical.png",
          "name": "Critical",
          "id": "2"
        },
        {
          "self": "http://jiraserver.example.com/rest/api/2/priority/3",
          "iconUrl": "http://jiraserver.example.com/images/icons/priorities/major.png",
          "name": "Major",
          "id": "3"
        },
        {
          "self": "http://jiraserver.example.com/rest/api/2/priority/4",
          "iconUrl": "http://jiraserver.example.com/images/icons/priorities/minor.png",
          "name": "Minor",
          "id": "4"
        },
        {
          "self": "http://jiraserver.example.com/rest/api/2/priority/5",
          "iconUrl": "http://jiraserver.example.com/images/icons/priorities/trivial.png",
          "name": "Trivial",
          "id": "5"
        }
      ]
    }
  }
}
'@
        $sampleObject = ConvertFrom-Json2 -InputObject $sampleJson

        $r = ConvertTo-JiraEditMetaField $sampleObject

        It "Creates PSObjects out of JSON input" {
            $r | Should Not BeNullOrEmpty
            $r.Count | Should Be 2
        }

        checkIsArray $r
        checkPsType $r[0] 'PSJira.EditMetaField'

        Context "Data validation" {
            # Our sample JSON includes two fields: summary and priority.
            $summary = ConvertTo-JiraEditMetaField $sampleObject | Where-Object -FilterScript {$_.Name -eq 'Summary'}
            $priority = ConvertTo-JiraEditMetaField $sampleObject | Where-Object -FilterScript {$_.Name -eq 'Priority'}

            defProp $summary 'Id' 'summary'
            defProp $summary 'Name' 'Summary'
            defProp $summary 'HasDefaultValue' $false
            defProp $summary 'Required' $true
            defProp $summary 'Operations' @('set')

            It "Defines the 'Schema' property if available" {
                $summary.Schema | Should Not BeNullOrEmpty
                $priority.Schema | Should Not BeNullOrEmpty
            }

            It "Defines the 'AllowedValues' property if available" {
                $summary.AllowedValues | Should BeNullOrEmpty
                $priority.AllowedValues | Should Not BeNullOrEmpty
            }
        }
    }
}
