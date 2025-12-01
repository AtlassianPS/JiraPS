#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "Validation of example codes in the documentation" -Tag Documentation, NotImplemented {
    BeforeDiscovery {
        . "$PSScriptRoot/Helpers/Resolve-ModuleSource.ps1"
        $script:moduleToTest = Resolve-ModuleSource

        $dependentModules = Get-Module | Where-Object { $_.RequiredModules.Name -eq 'JiraPS' }
    $dependentModules, "JiraPS" | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module $moduleToTest -Force -ErrorAction Stop

        $script:commands = Get-Command -Module JiraPS -CommandType Cmdlet, Function
    }
    BeforeAll {
        $script:module = Get-Module JiraPS
    }

    Describe "Examples" {
        Describe "Examples for <_.Name>" -ForEach $commands {
            BeforeAll {
                $script:command = $_
                $script:help = Get-Help $command
            }

            # TODO:
        }
    }
}
