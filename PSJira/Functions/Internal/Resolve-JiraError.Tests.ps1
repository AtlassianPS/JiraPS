$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {
    Describe "Resolve-JiraError" {

        $testErrorKey = 'error'
        $testError = 'This is an error message.'

$testJson = @"
{
    "errorMessages": [],
    "errors":
    {
        "$testErrorKey":"$testError"
    }
}
"@
        $testErrorMessage = "JIRA encountered an error: [$testErrorKey] - $testError"

        It "Converts a JIRA result into a PSObject with error results" {
            $obj = Resolve-JiraError -InputObject (ConvertFrom-Json2 $testJson)
            $obj | Should Not BeNullOrEmpty
            $obj.Key | Should Be $testErrorKey
            $obj.Message | Should Be $testError
        }

        It "Writes output to the Error stream if the -WriteError parameter is passed" {
            $obj = Resolve-JiraError -InputObject (ConvertFrom-Json2 $testJson) -WriteError -ErrorAction SilentlyContinue -ErrorVariable errOutput
            $errOutput | Should Be $testErrorMessage
        }

        It "Does not write a PSObject if the -WriteError parameter is passed" {
            $obj = Resolve-JiraError -InputObject (ConvertFrom-Json2 $testJson) -WriteError -ErrorAction SilentlyContinue -ErrorVariable errOutput
            $obj | Should BeNullOrEmpty
        }
    }
}
