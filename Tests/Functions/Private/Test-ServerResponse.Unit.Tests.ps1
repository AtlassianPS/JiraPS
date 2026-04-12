#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "Test-ServerResponse" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            Mock Start-Sleep -ModuleName JiraPS { }
        }

        Describe "Rate Limit Handling (HTTP 429)" {
            It "returns `$true when status code is 429 and retries remain" {
                $response = [PSCustomObject]@{
                    StatusCode = 429
                    Headers    = @{}
                }

                $result = Test-ServerResponse -InputObject $response -RetryCount 0 -MaxRetries 3
                $result | Should -BeTrue
            }

            It "sleeps before signaling retry" {
                $response = [PSCustomObject]@{
                    StatusCode = 429
                    Headers    = @{}
                }

                $null = Test-ServerResponse -InputObject $response -RetryCount 0 -MaxRetries 3

                Should -Invoke -CommandName Start-Sleep -ModuleName JiraPS -Exactly -Times 1
            }

            It "respects the Retry-After header" {
                $response = [PSCustomObject]@{
                    StatusCode = 429
                    Headers    = @{ 'Retry-After' = '10' }
                }

                $null = Test-ServerResponse -InputObject $response -RetryCount 0 -MaxRetries 3

                Should -Invoke -CommandName Start-Sleep -ModuleName JiraPS -ParameterFilter { $Seconds -eq 10 } -Exactly -Times 1
            }

            It "uses exponential backoff when Retry-After is absent" {
                $response = [PSCustomObject]@{
                    StatusCode = 429
                    Headers    = @{}
                }

                $null = Test-ServerResponse -InputObject $response -RetryCount 0 -MaxRetries 3
                Should -Invoke -CommandName Start-Sleep -ModuleName JiraPS -ParameterFilter { $Seconds -eq 2 } -Exactly -Times 1

                $null = Test-ServerResponse -InputObject $response -RetryCount 1 -MaxRetries 3
                Should -Invoke -CommandName Start-Sleep -ModuleName JiraPS -ParameterFilter { $Seconds -eq 4 } -Exactly -Times 1

                $null = Test-ServerResponse -InputObject $response -RetryCount 2 -MaxRetries 3
                Should -Invoke -CommandName Start-Sleep -ModuleName JiraPS -ParameterFilter { $Seconds -eq 8 } -Exactly -Times 1
            }

            It "does not signal retry when max retries are exhausted" {
                $response = [PSCustomObject]@{
                    StatusCode = 429
                    Headers    = @{}
                }

                $result = Test-ServerResponse -InputObject $response -RetryCount 3 -MaxRetries 3
                $result | Should -BeNullOrEmpty
            }

            It "does not sleep when max retries are exhausted" {
                $response = [PSCustomObject]@{
                    StatusCode = 429
                    Headers    = @{}
                }

                $null = Test-ServerResponse -InputObject $response -RetryCount 3 -MaxRetries 3

                Should -Invoke -CommandName Start-Sleep -ModuleName JiraPS -Exactly -Times 0
            }

            It "emits a warning on 429" {
                $response = [PSCustomObject]@{
                    StatusCode = 429
                    Headers    = @{}
                }

                $null = Test-ServerResponse -InputObject $response -RetryCount 0 -MaxRetries 3 -WarningVariable warn -WarningAction SilentlyContinue
                $warn | Should -Match '429'
            }
        }

        Describe "Non-429 Responses" {
            It "returns nothing for a successful response" {
                $response = [PSCustomObject]@{
                    StatusCode = 200
                    Headers    = @{}
                }

                $result = Test-ServerResponse -InputObject $response
                $result | Should -BeNullOrEmpty
            }

            It "returns nothing for a 500 error" {
                $response = [PSCustomObject]@{
                    StatusCode = 500
                    Headers    = @{}
                }

                $result = Test-ServerResponse -InputObject $response
                $result | Should -BeNullOrEmpty
            }

            It "returns nothing for a null response" {
                $result = Test-ServerResponse -InputObject $null
                $result | Should -BeNullOrEmpty
            }
        }
    }
}
