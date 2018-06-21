Describe "ConvertTo-JiraProjectRole" {

    Import-Module "$PSScriptRoot/../JiraPS" -Force -ErrorAction Stop

    InModuleScope JiraPS {

        . "$PSScriptRoot/Shared.ps1"

        $sampleJson = @"
[
  {
    "self": "http://www.example.com/jira/rest/api/2/project/MKY/role/10360",
    "name": "Developers",
    "id": 10360,
    "description": "A project role that represents developers in a project",
    "actors": [
      {
        "id": 10240,
        "displayName": "jira-developers",
        "type": "atlassian-group-role-actor",
        "name": "jira-developers"
      },
      {
        "id": 10241,
        "displayName": "Fred F. User",
        "type": "atlassian-user-role-actor",
        "name": "fred"
      }
    ]
  }
]
"@

        $sampleObject = ConvertFrom-Json -InputObject $sampleJson
        $r = ConvertTo-JiraProjectRole -InputObject $sampleObject

        It "Creates a PSObject out of JSON input" {
            $r | Should -Not -BeNullOrEmpty
        }

        checkPsType $r 'JiraPS.ProjectRole'

        defProp $r 'Id' 10360
        defProp $r 'Name' "Developers"
        defProp $r 'Description' "A project role that represents developers in a project"
        hasProp $r 'Actors'
        defProp $r 'RestUrl' "http://www.example.com/jira/rest/api/2/project/MKY/role/10360"
    }
}
