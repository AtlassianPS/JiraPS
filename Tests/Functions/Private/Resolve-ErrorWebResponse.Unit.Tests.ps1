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

        function Invoke-ResolveErrorWebResponseUnderTest {
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
        }

        It "writes field-level errors returned via the Jira errors object" {
            $responseBody = '{"errors":{"attachment":"Attachment is required."}}'

            Invoke-ResolveErrorWebResponseUnderTest -ResponseBody $responseBody

            Should -Invoke -CommandName WriteError -ModuleName JiraPS -Times 1 -ParameterFilter {
                $ErrorId -eq 'InvalidResponse.Status400' -and
                $Category -eq 'InvalidResult' -and
                $Message -eq 'Attachment is required.'
            }
        }
    }
}
