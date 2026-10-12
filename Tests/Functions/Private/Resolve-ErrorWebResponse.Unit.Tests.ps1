#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Resolve-ErrorWebResponse" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            function Get-TestErrorResponse {
                param([string]$Body)

                $stream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($Body))
                [PSCustomObject]@{ Stream = $stream } |
                    Add-Member -MemberType ScriptMethod -Name GetResponseStream -Value { $this.Stream } -PassThru
            }
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
                    Exception    = [PSCustomObject]@{
                        Response = Get-TestErrorResponse -Body $ResponseBody
                    }
                }

                Resolve-ErrorWebResponse -Exception $exception -StatusCode ([System.Net.HttpStatusCode]::BadRequest) -Cmdlet $PSCmdlet
            } -ResponseBody $responseBody

            Should -Invoke -CommandName WriteError -ModuleName JiraPS -Times 1 -ParameterFilter {
                $ErrorId -eq 'InvalidResponse.Status400' -and
                $Category -eq 'InvalidResult' -and
                $Message -eq 'attachment: Attachment is required.'
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
                    Exception    = [PSCustomObject]@{
                        Response = Get-TestErrorResponse -Body $ResponseBody
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
                    Exception    = [PSCustomObject]@{
                        Response = Get-TestErrorResponse -Body $ResponseBody
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
                    Exception    = [PSCustomObject]@{
                        Response = Get-TestErrorResponse -Body $ResponseBody
                    }
                }

                Resolve-ErrorWebResponse -Exception $exception -StatusCode ([System.Net.HttpStatusCode]::BadRequest) -Cmdlet $PSCmdlet
            } -ResponseBody $responseBody

            Should -Invoke -CommandName WriteError -ModuleName JiraPS -Times 2
            Should -Invoke -CommandName WriteError -ModuleName JiraPS -Times 1 -ParameterFilter { $Message -eq 'attachment: Attachment is required.' }
            Should -Invoke -CommandName WriteError -ModuleName JiraPS -Times 1 -ParameterFilter { $Message -eq 'customfield_10001: Approver is required.' }
        }

        It "writes both top-level and field-level errors when Jira returns both payload shapes" {
            $responseBody = '{"errorMessages":["Top-level failure"],"errors":{"attachment":"Attachment is required."}}'

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
                    Exception    = [PSCustomObject]@{
                        Response = Get-TestErrorResponse -Body $ResponseBody
                    }
                }

                Resolve-ErrorWebResponse -Exception $exception -StatusCode ([System.Net.HttpStatusCode]::BadRequest) -Cmdlet $PSCmdlet
            } -ResponseBody $responseBody

            Should -Invoke -CommandName WriteError -ModuleName JiraPS -Times 2
            Should -Invoke -CommandName WriteError -ModuleName JiraPS -Times 1 -ParameterFilter { $Message -eq 'Top-level failure' }
            Should -Invoke -CommandName WriteError -ModuleName JiraPS -Times 1 -ParameterFilter { $Message -eq 'attachment: Attachment is required.' }
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
                    Exception    = [PSCustomObject]@{
                        Response = Get-TestErrorResponse -Body $ResponseBody
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
                    Exception    = [PSCustomObject]@{
                        Response = Get-TestErrorResponse -Body $ResponseBody
                    }
                }

                Resolve-ErrorWebResponse -Exception $exception -StatusCode ([System.Net.HttpStatusCode]::BadRequest) -Cmdlet $PSCmdlet
            } -ResponseBody $responseBody

            Should -Invoke -CommandName WriteError -ModuleName JiraPS -Times 1 -ParameterFilter { $Message -eq 'An unknown error occurred.' }
        }

        It "writes a generic error when Jira returns empty errorMessages and errors payloads" {
            $responseBody = '{"errorMessages":[],"errors":{}}'

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
                    Exception    = [PSCustomObject]@{
                        Response = Get-TestErrorResponse -Body $ResponseBody
                    }
                }

                Resolve-ErrorWebResponse -Exception $exception -StatusCode ([System.Net.HttpStatusCode]::BadRequest) -Cmdlet $PSCmdlet
            } -ResponseBody $responseBody

            Should -Invoke -CommandName WriteError -ModuleName JiraPS -Times 1 -ParameterFilter { $Message -eq 'An unknown error occurred.' }
        }
        Context "<Edition> response reading" -ForEach @(
            @{ Edition = 'Core' }
            @{ Edition = 'Desktop' }
        ) {
            BeforeAll {
                Add-Type -AssemblyName System.Net.Http
                $script:originalPSVersionTable = $PSVersionTable
                $script:PSVersionTable = $PSVersionTable.Clone()
                $script:PSVersionTable.PSEdition = $Edition
            }

            AfterAll {
                $script:PSVersionTable = $script:originalPSVersionTable
            }

            BeforeEach {
                $script:response = if ($Edition -eq 'Core') { [System.Net.Http.HttpResponseMessage]::new() }
                else { Get-TestErrorResponse -Body '' }
                $script:exception = [PSCustomObject]@{
                    ErrorDetails = $null
                    Exception    = [PSCustomObject]@{ Response = $response }
                }
            }

            AfterEach {
                if ($Edition -eq 'Core') { $response.Dispose() }
                elseif ($response.Stream) { $response.Stream.Dispose() }
            }

            It "reports HTTP <Status> with <Details> ErrorDetails and no body" -ForEach @(
                @{ Status = 400; Details = 'null' }
                @{ Status = 404; Details = 'null' }
                @{ Status = 500; Details = 'null' }
                @{ Status = 404; Details = 'empty' }
            ) {
                if ($Details -eq 'empty') { $exception.ErrorDetails = [PSCustomObject]@{ Message = '' } }
                $expectedMessage = "Server responded with $([System.Net.HttpStatusCode]$Status)"
                $expectedErrorId = "InvalidResponse.Status$Status"

                { Resolve-ErrorWebResponse -Exception $exception -StatusCode ([System.Net.HttpStatusCode]$Status) } |
                    Should -Not -Throw

                Should -Invoke -CommandName WriteError -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $ErrorId -eq $expectedErrorId -and
                    $Category -eq 'InvalidResult' -and
                    $Message -eq $expectedMessage
                }
            }

            It "reports the HTTP status when the response is null" {
                $exception.Exception.Response = $null

                { Resolve-ErrorWebResponse -Exception $exception -StatusCode ([System.Net.HttpStatusCode]::NotFound) } |
                    Should -Not -Throw

                Should -Invoke -CommandName WriteError -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $ErrorId -eq 'InvalidResponse.Status404' -and
                    $Message -eq 'Server responded with NotFound'
                }
            }

            It "uses the edition's response body for Jira messages" {
                $body = '{"errorMessages":["Top-level failure"],"errors":{"summary":"Summary is required."}}'
                if ($Edition -eq 'Core') { $exception.ErrorDetails = [PSCustomObject]@{ Message = $body } }
                else {
                    $response.Stream.Dispose()
                    $response.Stream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($body))
                    $exception.ErrorDetails = [PSCustomObject]@{ Message = '{"message":"Wrong body"}' }
                }

                { Resolve-ErrorWebResponse -Exception $exception -StatusCode ([System.Net.HttpStatusCode]::BadRequest) } |
                    Should -Not -Throw

                Should -Invoke -CommandName WriteError -ModuleName JiraPS -Exactly -Times 2
                Should -Invoke -CommandName WriteError -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $Message -eq 'Top-level failure'
                }
                Should -Invoke -CommandName WriteError -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $Message -eq 'summary: Summary is required.'
                }
            }

            It "reports the HTTP status when the Desktop stream is null" -Skip:($Edition -ne 'Desktop') {
                $response.Stream.Dispose()
                $response.Stream = $null

                { Resolve-ErrorWebResponse -Exception $exception -StatusCode ([System.Net.HttpStatusCode]::NotFound) } |
                    Should -Not -Throw

                Should -Invoke -CommandName WriteError -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                    $ErrorId -eq 'InvalidResponse.Status404' -and
                    $Message -eq 'Server responded with NotFound'
                }
            }
        }
    }
}
