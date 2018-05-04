Describe "ConvertTo-JiraComponent" {

    Import-Module "$PSScriptRoot/../JiraPS" -Force -ErrorAction Stop

    InModuleScope JiraPS {

        . "$PSScriptRoot/Shared.ps1"

        $jiraServer = 'http://jiraserver.example.com'

        $sampleJson = @"
{
    "self": "$jiraServer/rest/api/2/component/11000",
    "id": "11000",
    "name": "test component"
}
"@
        $sampleObject = ConvertFrom-Json -InputObject $sampleJson

        $r = ConvertTo-JiraComponent -InputObject $sampleObject

        It "Creates a PSObject out of JSON input" {
            $r | Should Not BeNullOrEmpty
        }

        It "Sets the type name to JiraPS.Project" {
            # (Get-Member -InputObject $r).TypeName | Should Be 'JiraPS.Component'
            checkType $r "JiraPS.Component"
        }

        defProp $r 'Id' '11000'
        defProp $r 'Name' 'test component'
        defProp $r 'RestUrl' "$jiraServer/rest/api/2/component/11000"
    }
}
