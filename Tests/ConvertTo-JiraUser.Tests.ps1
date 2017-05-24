. $PSScriptRoot\Shared.ps1

InModuleScope PSJira {
    Describe "ConvertTo-JiraUser" {
        . $PSScriptRoot\Shared.ps1

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

        checkPsType $r 'PSJira.User'

        defProp $r 'Name' $username
        defProp $r 'DisplayName' $displayName
        defProp $r 'EmailAddress' $email
        defProp $r 'Active' $true
        defProp $r 'RestUrl' "$jiraServer/rest/api/2/user?username=$username"
    }
}
