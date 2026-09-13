#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2.0"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
    $script:commands = Get-Command -Module JiraPS -CommandType Cmdlet, Function
}

Describe "Validation of example codes in the documentation" -Tag Documentation, NotImplemented {
    Describe "Examples" {
        Describe "Examples for <_.Name>" -ForEach $commands {
            BeforeAll {
                $script:command = $_
                $script:help = Get-Help $command
            }

            # TODO:
            It "should have examples implemented as tests" -Skip {
                $true | Should -Be $true
            }
        }
    }
}
