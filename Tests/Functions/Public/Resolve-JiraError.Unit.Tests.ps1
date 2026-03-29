#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Resolve-JiraError" -Tag 'Unit' {
        BeforeAll {
            $script:testErrorKey = 'error'
            $script:testError = 'This is an error message.'

            $script:testJson = @"
{
    "errorMessages": [],
    "errors":
    {
        "$testErrorKey":"$testError"
    }
}
"@
            $script:testErrorMessage = "Jira encountered an error: [$testErrorKey] - $testError"
        }

        It "Converts a JIRA result into a PSObject with error results" {
            $obj = Resolve-JiraError -InputObject (ConvertFrom-Json $testJson)
            $obj | Should -Not -BeNullOrEmpty
            $obj.Key | Should -Be $testErrorKey
            $obj.Message | Should -Be $testError
        }

        It "Writes output to the Error stream if the -WriteError parameter is passed" {
            $null = Resolve-JiraError -InputObject (ConvertFrom-Json $testJson) -WriteError -ErrorAction SilentlyContinue -ErrorVariable errOutput
            $errOutput | Should -Be $testErrorMessage
        }

        It "Does not write a PSObject if the -WriteError parameter is passed" {
            $obj = Resolve-JiraError -InputObject (ConvertFrom-Json $testJson) -WriteError -ErrorAction SilentlyContinue -ErrorVariable errOutput
            $obj | Should -BeNullOrEmpty
        }
    }
}
