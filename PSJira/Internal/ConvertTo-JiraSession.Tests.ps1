$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {
    Describe "ConvertTo-JiraSession" {
        function defProp($obj, $propName, $propValue)
        {
            It "Defines the '$propName' property" {
                $obj.$propName | Should Be $propValue
            }
        }

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

        It "Sets the type name to PSJira.Session" {
            $r | Test-HasTypeName 'PSJira.Session' | Should Be $True
        }

        defProp $r 'Username' $sampleUsername
        defProp $r 'JSessionID' $sampleJSessionID
    }
}
 