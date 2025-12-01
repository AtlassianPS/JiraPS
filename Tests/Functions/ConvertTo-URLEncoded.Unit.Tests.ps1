#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "ConvertTo-URLEncoded" -Tag 'Unit' {

    BeforeAll {
        . "$PSScriptRoot/../../Tests/Helpers/Resolve-ModuleSource.ps1"
        $moduleToTest = Resolve-ModuleSource
        Import-Module $moduleToTest -Force
    }
    AfterAll {
        Remove-Module JiraPS -ErrorAction SilentlyContinue
    }

    InModuleScope JiraPS {

        . "$PSScriptRoot/../Shared.ps1"

        Context "Sanity checking" {
            $command = Get-Command -Name ConvertTo-URLEncoded

            defParam $command 'InputString'
        }
        Context "Handling of Inputs" {
            It "does not not allow a null or empty input" {
                { ConvertTo-URLEncoded -InputString $null } | Should -Throw
                { ConvertTo-URLEncoded -InputString "" } | Should -Throw
            }
            It "accepts pipeline input" {
                { "lorem ipsum" | ConvertTo-URLEncoded } | Should -Not Throw
            }
            It "accepts multiple InputStrings" {
                { ConvertTo-URLEncoded -InputString "lorem", "ipsum" } | Should -Not Throw
                { "lorem", "ipsum" | ConvertTo-URLEncoded } | Should -Not Throw
            }
        }
        Context "Handling of Outputs" {
            It "returns as many objects as inputs where provided" {
                $r1 = ConvertTo-URLEncoded -InputString "lorem"
                $r2 = "lorem", "ipsum" | ConvertTo-URLEncoded
                $r3 = ConvertTo-URLEncoded -InputString "lorem", "ipsum", "dolor"

                @($r1).Count | Should -Be 1
                @($r2).Count | Should -Be 2
                @($r3).Count | Should -Be 3
            }
            It "decodes URL encoded strings" {
                $output = ConvertTo-URLEncoded -InputString 'Hello World?'
                $output | Should -Be "Hello+World%3F"
            }
        }
    }
}
