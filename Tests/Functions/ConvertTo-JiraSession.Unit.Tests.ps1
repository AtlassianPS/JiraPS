#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

# Import module at script level for Pester v5 InModuleScope compatibility
. "$PSScriptRoot/../../Tests/Helpers/Resolve-ModuleSource.ps1"
$moduleToTest = Resolve-ModuleSource
Import-Module $moduleToTest -Force

Describe "ConvertTo-JiraSession" -Tag 'Unit' {
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
