#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "ConvertTo-JiraSession" -Tag 'Unit' {

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

        $sampleUsername = 'powershell-test'
        $sampleSession = @{}

        $r = ConvertTo-JiraSession -Session $sampleSession -Username $sampleUsername

        It "Creates a PSObject out of Web request data" {
            $r | Should -Not -BeNullOrEmpty
        }

        checkPsType $r 'JiraPS.Session'
        defProp $r 'Username' $sampleUsername
    }
}
