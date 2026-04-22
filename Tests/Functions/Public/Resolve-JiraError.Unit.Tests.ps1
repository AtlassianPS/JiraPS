#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
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

        Describe "Jira 6.x errors dict format" {
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

        Describe "Jira 5.1 message format" {
            It "parses the 'message' key" {
                $json = '{ "message": "Something went wrong" }'
                $obj = Resolve-JiraError -InputObject (ConvertFrom-Json $json)

                $obj | Should -Not -BeNullOrEmpty
                $obj.Message | Should -Be "Something went wrong"
            }

            It "writes to error stream with -WriteError" {
                $json = '{ "message": "Something went wrong" }'
                $null = Resolve-JiraError -InputObject (ConvertFrom-Json $json) -WriteError -ErrorAction SilentlyContinue -ErrorVariable errOutput

                $errOutput | Should -Match "Something went wrong"
            }
        }

        Describe "Service unavailable errorMessage format" {
            It "parses the 'errorMessage' key" {
                $json = '{ "errorMessage": "Service temporarily unavailable" }'
                $obj = Resolve-JiraError -InputObject (ConvertFrom-Json $json)

                $obj | Should -Not -BeNullOrEmpty
                $obj.Message | Should -Be "Service temporarily unavailable"
            }
        }

        Describe "Jira 5.0.x errorMessages array format" {
            It "parses the 'errorMessages' array" {
                $json = '{ "errorMessages": ["Error 1", "Error 2"], "errors": {} }'
                $objs = Resolve-JiraError -InputObject (ConvertFrom-Json $json)

                $objs | Should -HaveCount 2
                $objs[0].Message | Should -Be "Error 1"
                $objs[1].Message | Should -Be "Error 2"
            }

            It "ignores empty errorMessages array" {
                $json = '{ "errorMessages": [], "errors": { "field": "Field error" } }'
                $objs = Resolve-JiraError -InputObject (ConvertFrom-Json $json)

                $objs | Should -HaveCount 1
                $objs.Key | Should -Be "field"
            }
        }

        Describe "Multiple error sources" {
            It "combines message and errorMessages" {
                $json = '{ "message": "Main error", "errorMessages": ["Detail 1"] }'
                $objs = Resolve-JiraError -InputObject (ConvertFrom-Json $json)

                $objs | Should -HaveCount 2
                ($objs | Where-Object { $_.Message -eq "Main error" }) | Should -Not -BeNullOrEmpty
                ($objs | Where-Object { $_.Message -eq "Detail 1" }) | Should -Not -BeNullOrEmpty
            }
        }

        Describe "Pipeline support" {
            It "accepts input from the pipeline" {
                $json1 = '{ "message": "Error 1" }'
                $json2 = '{ "message": "Error 2" }'
                $objs = (ConvertFrom-Json $json1), (ConvertFrom-Json $json2) | Resolve-JiraError

                $objs | Should -HaveCount 2
            }
        }

        Describe "Type information" {
            It "adds the JiraPS.Error type name" {
                $json = '{ "message": "Test error" }'
                $obj = Resolve-JiraError -InputObject (ConvertFrom-Json $json)

                $obj.PSObject.TypeNames[0] | Should -Be 'JiraPS.Error'
            }

            It "has a ToString method" {
                $json = '{ "message": "Test error" }'
                $obj = Resolve-JiraError -InputObject (ConvertFrom-Json $json)

                $obj.ToString() | Should -Match "Test error"
            }
        }
    }
}
