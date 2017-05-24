. $PSScriptRoot\Shared.ps1

InModuleScope PSJira {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '', Scope='*', Target='SuppressImportModule')]
    $SuppressImportModule = $true
    . $PSScriptRoot\Shared.ps1

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
        $testErrorMessage = "Jira encountered an error: [$testErrorKey] - $testError" #Question: Should this be JIRA or Jira; should be consisnent throughout the code.

        It "Converts a JIRA result into a PSObject with error results" {
            $obj = Resolve-JiraError -InputObject (ConvertFrom-Json2 $testJson)
            $obj | Should Not BeNullOrEmpty
            $obj.Key | Should Be $testErrorKey
            $obj.Message | Should Be $testError
        }

        It "Writes output to the Error stream if the -WriteError parameter is passed" {
            $obj = Resolve-JiraError -InputObject (ConvertFrom-Json2 $testJson) -WriteError -ErrorAction SilentlyContinue -ErrorVariable errOutput
            ([string]$errOutput) | Should Be $testErrorMessage #$errOutput is of type System.Collections.ArrayList; not string, hence adding the cast in this test
        }

        It "Does not write a PSObject if the -WriteError parameter is passed" {
            $obj = Resolve-JiraError -InputObject (ConvertFrom-Json2 $testJson) -WriteError -ErrorAction SilentlyContinue -ErrorVariable errOutput
            $obj | Should BeNullOrEmpty
        }
    }
}
