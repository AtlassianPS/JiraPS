#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Write-DebugMessage" -Tag Unit {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            function Invoke-DiagnosticChild {
                [CmdletBinding()]
                param()

                Write-DebugMessage -BoundParameters @{ Key = 'TEST-1'; ApiToken = 'sentinel-token' }
            }

            function Invoke-DiagnosticParent {
                [CmdletBinding()]
                param()

                Invoke-DiagnosticChild
            }

            $script:originalStyle = & (Get-Module AtlassianPS.Configuration) { $script:Configuration['Message'] }
        }

        AfterEach {
            & (Get-Module AtlassianPS.Configuration) { param($Style) $script:Configuration['Message'] = $Style } $script:originalStyle
        }

        It "uses Configuration breadcrumbs across the module boundary" {
            & (Get-Module AtlassianPS.Configuration) { $script:Configuration['Message'] = [AtlassianPS.MessageStyle]::new(2, $false, $true, $false) }

            $output = Invoke-DiagnosticParent -Debug 5>&1 | Out-String

            $output | Should -Match '\[Invoke-DiagnosticChild > Invoke-DiagnosticParent'
            $output | Should -Match 'PSBoundParameters:'
            $output | Should -Match 'TEST-1'
            $output | Should -Not -Match 'sentinel-token|Write-DebugMessage|Format-MessageStyle'
        }

        It "uses the Jira caller name when breadcrumbs are disabled" {
            & (Get-Module AtlassianPS.Configuration) { $script:Configuration['Message'] = [AtlassianPS.MessageStyle]::new(0, $false, $false, $true) }

            $output = Invoke-DiagnosticParent -Debug 5>&1 | Out-String

            $output | Should -Match '\[Invoke-DiagnosticChild\] PSBoundParameters:'
        }

        It "emits no debug records when debugging is disabled" {
            $output = Invoke-DiagnosticParent -Debug:$false 5>&1

            $output | Should -BeNullOrEmpty
        }

        It "restores parameter diagnostics before connection resolution fails" {
            Mock New-JiraCandidate { throw 'expected-diagnostic-failure' }
            $script:diagnosticError = $null
            $output = & {
                try { Connect-Jira -Name diagnostic -Uri https://example.com -ApiToken sentinel-token -Debug }
                catch { $script:diagnosticError = $_ }
            } 5>&1 | Out-String

            $output | Should -Match 'Connect-Jira'
            $output | Should -Match 'PSBoundParameters:'
            $output | Should -Match 'diagnostic'
            $output | Should -Not -Match 'sentinel-token'
            $script:diagnosticError.Exception.Message | Should -Be 'expected-diagnostic-failure'
        }
    }
}
