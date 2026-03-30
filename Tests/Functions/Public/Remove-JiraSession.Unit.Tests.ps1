#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "Remove-JiraSession" -Tag 'Unit' {

    BeforeAll {
        . "$PSScriptRoot/../../Helpers/TestTools.ps1"
        # $VerbosePreference = 'Continue'

        Initialize-TestEnvironment
        $script:moduleToTest = Resolve-ModuleSource

        Import-Module $script:moduleToTest -Force -ErrorAction Stop

        #region Definitions
        #endregion Definitions

        #region Mocks
        Mock Get-JiraSession -ModuleName JiraPS {
            Write-MockDebugInfo 'Get-JiraSession'
            (Get-Module JiraPS).PrivateData.Session
        }
        #endregion Mocks
    }

    Describe "Signature" {
        BeforeAll {
            $script:command = Get-Command -Name Remove-JiraSession
        }

        Context "Parameter Types" {
            It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                @{ parameter = 'Session'; type = 'Object' }
            ) {
                param($parameter, $type)
                $command | Should -HaveParameter $parameter -Type $type
            }
        }

        Context "Mandatory Parameters" {
            # TODO: Add tests for mandatory parameters
        }

        Context "Default Values" {
            # TODO: Add tests for parameter default values
        }
    }

    Describe "Behavior" {
        Context "Session Cleanup" {
            It "Closes and removes the JiraPS.Session data from module PrivateData" {
                (Get-Module JiraPS).PrivateData = @{ Session = $true }
                (Get-Module JiraPS).PrivateData.Session | Should -Not -BeNullOrEmpty

                Remove-JiraSession

                (Get-Module JiraPS).PrivateData.Session | Should -BeNullOrEmpty
            }
        }
    }

    Describe "Input Validation" {
        Context "Positive cases" {
            # TODO: Add positive input validation tests
        }

        Context "Negative cases" {
            # TODO: Add negative input validation tests
        }
    }
}
