$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {
    Describe "ConvertTo-JiraUser" {
        function defProp($obj, $propName, $propValue)
        {
            It "Defines the '$propName' property" {
                $obj.$propName | Should Be $propValue
            }
        }

        $jiraServer = 'http://jiraserver.example.com'
        $username = 'powershell-test'
        $displayName = 'PowerShell Test User'
        $email = 'noreply@example.com'

        $sampleJson = @"
{
    "self": "$jiraServer/rest/api/2/user?username=$username",
    "key": "$username",
    "name": "$username",
    "emailAddress": "$email",
    "displayName": "$displayName",
    "active": true
}
"@
        $sampleObject = ConvertFrom-Json2 -InputObject $sampleJson

        $r = ConvertTo-JiraUser -InputObject $sampleObject

        It "Creates a PSObject out of JSON input" {
            $r | Should Not BeNullOrEmpty
        }

        It "Sets the type name to PSJira.Comment" {
            $r | Test-HasTypeName 'PSJira.User' | Should Be $True
        }

        defProp $r 'Name' $username
        defProp $r 'DisplayName' $displayName
        defProp $r 'EmailAddress' $email
        defProp $r 'Active' $true
        defProp $r 'RestUrl' "$jiraServer/rest/api/2/user?username=$username"
    }
}
