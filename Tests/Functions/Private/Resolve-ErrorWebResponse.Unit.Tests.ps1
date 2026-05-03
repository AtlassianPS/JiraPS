#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Resolve-ErrorWebResponse" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
        }

        BeforeEach {
            Mock WriteError -ModuleName JiraPS {}
        }

        It "writes field-level errors returned via the Jira errors object" {
            $responseBody = '{"errors":{"attachment":"Attachment is required."}}'

            & {
                [CmdletBinding()]
                param(
                    [Parameter(Mandatory)]
                    [string]
                    $ResponseBody
                )

                $exception = [PSCustomObject]@{
                    ErrorDetails = [PSCustomObject]@{
                        Message = $ResponseBody
                    }
                }

                Resolve-ErrorWebResponse -Exception $exception -StatusCode ([System.Net.HttpStatusCode]::BadRequest) -Cmdlet $PSCmdlet
            } -ResponseBody $responseBody

            Should -Invoke -CommandName WriteError -ModuleName JiraPS -Times 1 -ParameterFilter {
                $ErrorId -eq 'InvalidResponse.Status400' -and
                $Category -eq 'InvalidResult' -and
                $Message -eq 'Attachment is required.'
            }
        }

        It "writes error messages returned via the Jira errorMessages array" {
            $responseBody = '{"errorMessages":["Top-level failure","Second failure"]}'

            & {
                [CmdletBinding()]
                param(
                    [Parameter(Mandatory)]
                    [string]
                    $ResponseBody
                )

                $exception = [PSCustomObject]@{
                    ErrorDetails = [PSCustomObject]@{
                        Message = $ResponseBody
                    }
                }

                Resolve-ErrorWebResponse -Exception $exception -StatusCode ([System.Net.HttpStatusCode]::BadRequest) -Cmdlet $PSCmdlet
            } -ResponseBody $responseBody

            Should -Invoke -CommandName WriteError -ModuleName JiraPS -Times 2
            Should -Invoke -CommandName WriteError -ModuleName JiraPS -Times 1 -ParameterFilter { $Message -eq 'Top-level failure' }
            Should -Invoke -CommandName WriteError -ModuleName JiraPS -Times 1 -ParameterFilter { $Message -eq 'Second failure' }
        }

        It "writes the Jira message property when present" {
            $responseBody = '{"message":"Cloud validation failed."}'

            & {
                [CmdletBinding()]
                param(
                    [Parameter(Mandatory)]
                    [string]
                    $ResponseBody
                )

                $exception = [PSCustomObject]@{
                    ErrorDetails = [PSCustomObject]@{
                        Message = $ResponseBody
                    }
                }

                Resolve-ErrorWebResponse -Exception $exception -StatusCode ([System.Net.HttpStatusCode]::BadRequest) -Cmdlet $PSCmdlet
            } -ResponseBody $responseBody

            Should -Invoke -CommandName WriteError -ModuleName JiraPS -Times 1 -ParameterFilter { $Message -eq 'Cloud validation failed.' }
        }

        It "writes each field-level error when Jira returns multiple errors" {
            $responseBody = '{"errors":{"attachment":"Attachment is required.","customfield_10001":"Approver is required."}}'

            & {
                [CmdletBinding()]
                param(
                    [Parameter(Mandatory)]
                    [string]
                    $ResponseBody
                )

                $exception = [PSCustomObject]@{
                    ErrorDetails = [PSCustomObject]@{
                        Message = $ResponseBody
                    }
                }

                Resolve-ErrorWebResponse -Exception $exception -StatusCode ([System.Net.HttpStatusCode]::BadRequest) -Cmdlet $PSCmdlet
            } -ResponseBody $responseBody

            Should -Invoke -CommandName WriteError -ModuleName JiraPS -Times 2
            Should -Invoke -CommandName WriteError -ModuleName JiraPS -Times 1 -ParameterFilter { $Message -eq 'Attachment is required.' }
            Should -Invoke -CommandName WriteError -ModuleName JiraPS -Times 1 -ParameterFilter { $Message -eq 'Approver is required.' }
        }

        It "writes the raw response body when the response is not valid JSON" {
            $responseBody = 'This is not JSON.'

            & {
                [CmdletBinding()]
                param(
                    [Parameter(Mandatory)]
                    [string]
                    $ResponseBody
                )

                $exception = [PSCustomObject]@{
                    ErrorDetails = [PSCustomObject]@{
                        Message = $ResponseBody
                    }
                }

                Resolve-ErrorWebResponse -Exception $exception -StatusCode ([System.Net.HttpStatusCode]::BadRequest) -Cmdlet $PSCmdlet
            } -ResponseBody $responseBody

            Should -Invoke -CommandName WriteError -ModuleName JiraPS -Times 1 -ParameterFilter { $Message -eq 'This is not JSON.' }
        }

        It "writes a generic error when the JSON contains no usable error payload" {
            $responseBody = '{"foo":"bar"}'

            & {
                [CmdletBinding()]
                param(
                    [Parameter(Mandatory)]
                    [string]
                    $ResponseBody
                )

                $exception = [PSCustomObject]@{
                    ErrorDetails = [PSCustomObject]@{
                        Message = $ResponseBody
                    }
                }

                Resolve-ErrorWebResponse -Exception $exception -StatusCode ([System.Net.HttpStatusCode]::BadRequest) -Cmdlet $PSCmdlet
            } -ResponseBody $responseBody

            Should -Invoke -CommandName WriteError -ModuleName JiraPS -Times 1 -ParameterFilter { $Message -eq 'An unknown error occurred.' }
        }
    }
}
