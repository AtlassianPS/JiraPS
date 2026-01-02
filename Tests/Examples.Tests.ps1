#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

Describe "Validation of example codes in the documentation" -Tag Documentation, NotImplemented -Skip {
    BeforeAll {
        $script:commands = Get-Command -Module JiraPS -CommandType Cmdlet, Function
        $script:module = Get-Module JiraPS
    }

    Describe "Examples" {
        Describe "Examples for <_.Name>" -ForEach $commands {
            BeforeAll {
                $script:command = $_
                $script:help = Get-Help $command
            }

            # TODO:
            It "should have examples implemented as tests" {
                $true | Should -Be $true
            }
        }
    }
}
