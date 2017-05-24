. $PSScriptRoot\Shared.ps1

# This is a private function, so the test needs to be within the module's scope
InModuleScope PSJira {

    # A bit counter-intuitive to import this twice, but otherwise its functions
    # are outside the PSJira module scope. We need it outside to make sure the
    # module is loaded, and we need it inside to make sure functions are
    # available.
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

        It "Sets the type name to PSJira.Project" {
            # (Get-Member -InputObject $r).TypeName | Should Be 'PSJira.Component'
            $r.PSObject.TypeNames[0] | Should Be 'PSJira.Component'
        }

        defProp $r 'Id' '11000'
        defProp $r 'Name' 'test component'
        defProp $r 'RestUrl' "$jiraServer/rest/api/2/component/11000"
    }
}
