. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {

    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope = '*', Target = 'SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

    Describe "ConvertTo-JiraComponent" {
        $jiraServer = 'http://jiraserver.example.com'

        $sampleJson = @"
{
    "self": "$jiraServer/rest/api/2/component/11000",
    "id": "11000",
    "name": "test component"
}
"@
        $sampleObject = ConvertFrom-Json2 -InputObject $sampleJson

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
