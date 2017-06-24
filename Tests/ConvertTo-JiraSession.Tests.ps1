. $PSScriptRoot\Shared.ps1

InModuleScope JiraPS {
    . $PSScriptRoot\Shared.ps1
    Describe "ConvertTo-JiraSession" {

        $sampleUsername = 'powershell-test'
        $sampleJSessionID = '76449957D8C863BE8D4F6F5507E980E8'
        $sampleSession = @{}
        $sampleWebResponse = @"
{
  "session": {
    "name": "JSESSIONID",
    "value": "$sampleJSessionID"
  },
  "loginInfo": {
    "failedLoginCount": 5,
    "loginCount": 50
  }
}
"@

        $r = ConvertTo-JiraSession -WebResponse $sampleWebResponse -Session $sampleSession -Username $sampleUsername

        It "Creates a PSObject out of Web request data" {
            $r | Should Not BeNullOrEmpty
        }

        checkPsType $r 'JiraPS.Session'

        defProp $r 'Username' $sampleUsername
        defProp $r 'JSessionID' $sampleJSessionID
    }
}
