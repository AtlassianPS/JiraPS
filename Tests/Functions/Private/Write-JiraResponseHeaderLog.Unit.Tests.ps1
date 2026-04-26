#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Write-JiraResponseHeaderLog" -Tag 'Unit' {
        BeforeEach {
            $script:JiraResponseHeaderLogConfiguration = $null
        }

        BeforeAll {
            Mock Write-DebugMessage -ModuleName 'JiraPS' {}
        }

        It "returns silently when InputObject is null" {
            $script:JiraResponseHeaderLogConfiguration = [PSCustomObject]@{
                Match = { param($name) $true }
            }

            { Write-JiraResponseHeaderLog -InputObject $null } | Should -Not -Throw

            Should -Invoke -CommandName Write-DebugMessage -ModuleName 'JiraPS' -Exactly -Times 0 -Scope It
        }

        It "returns silently when InputObject has no Headers property" {
            $script:JiraResponseHeaderLogConfiguration = [PSCustomObject]@{
                Match = { param($name) $true }
            }
            $response = [PSCustomObject]@{ StatusCode = 200 }

            { Write-JiraResponseHeaderLog -InputObject $response } | Should -Not -Throw

            Should -Invoke -CommandName Write-DebugMessage -ModuleName 'JiraPS' -Exactly -Times 0 -Scope It
        }

        It "returns silently when no configuration is set" {
            $response = [PSCustomObject]@{
                Headers = @{ 'X-AREQUESTID' = 'request-123' }
            }

            Write-JiraResponseHeaderLog -InputObject $response

            Should -Invoke -CommandName Write-DebugMessage -ModuleName 'JiraPS' -Exactly -Times 0 -Scope It
        }

        It "writes a debug message containing matched headers" {
            $script:JiraResponseHeaderLogConfiguration = [PSCustomObject]@{
                Match = { param($name) $name -like 'X-A*' }
            }
            $response = [PSCustomObject]@{
                Headers = @{
                    'X-AREQUESTID' = 'request-123'
                    'Server'       = 'jira'
                }
            }

            Write-JiraResponseHeaderLog -InputObject $response

            Should -Invoke -CommandName Write-DebugMessage -ModuleName 'JiraPS' -ParameterFilter {
                $Message -like '*X-AREQUESTID*request-123*' -and
                $Message -notlike '*Server*'
            } -Exactly -Times 1 -Scope It
        }

        It "always suppresses cookie and authorization headers regardless of matcher" {
            $script:JiraResponseHeaderLogConfiguration = [PSCustomObject]@{
                Match = { param($name) $true }
            }
            $response = [PSCustomObject]@{
                Headers = @{
                    'Set-Cookie'          = 'sid=cookie-secret'
                    'Set-Cookie2'         = 'session=cookie2-secret'
                    'Authorization'       = 'Bearer auth-secret'
                    'Proxy-Authorization' = 'Basic proxy-secret'
                    'X-ANODEID'           = 'node-1'
                }
            }

            Write-JiraResponseHeaderLog -InputObject $response

            Should -Invoke -CommandName Write-DebugMessage -ModuleName 'JiraPS' -ParameterFilter {
                $Message -like '*X-ANODEID*node-1*' -and
                $Message -notlike '*cookie-secret*' -and
                $Message -notlike '*cookie2-secret*' -and
                $Message -notlike '*auth-secret*' -and
                $Message -notlike '*proxy-secret*'
            } -Exactly -Times 1 -Scope It
        }

        It "flattens IEnumerable[string] header values into a comma-separated list" {
            $script:JiraResponseHeaderLogConfiguration = [PSCustomObject]@{
                Match = { param($name) $true }
            }
            $response = [PSCustomObject]@{
                Headers = @{
                    'X-AREQUESTID' = @('request-123', 'request-456')
                }
            }

            Write-JiraResponseHeaderLog -InputObject $response

            Should -Invoke -CommandName Write-DebugMessage -ModuleName 'JiraPS' -ParameterFilter {
                $Message -like '*request-123, request-456*'
            } -Exactly -Times 1 -Scope It
        }
    }
}
