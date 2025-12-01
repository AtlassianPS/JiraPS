#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "General project validation" -Tag Unit {
    BeforeAll {
        . "$PSScriptRoot/Helpers/Resolve-ModuleSource.ps1"
        . "$PSScriptRoot/Helpers/Resolve-ProjectRoot.ps1"
        $script:moduleToTest = Resolve-ModuleSource

        $dependentModules = Get-Module | Where-Object { $_.RequiredModules.Name -eq 'JiraPS' }
    $dependentModules, "JiraPS" | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module $moduleToTest -Force -ErrorAction Stop

        $script:module = Get-Module JiraPS
        $script:moduleRoot = Resolve-ProjectRoot
        $script:testFiles = Get-ChildItem $PSScriptRoot -Include "*.Tests.ps1" -Recurse
        $script:publicFunctionFiles = $module.ExportedFunctions.Keys
        $script:privateFunctionFiles = $module.Invoke({ Get-Command -Module JiraPS | Where-Object { $_.Name -notin $publicFunctionFiles } }).Name
    }

    Describe "Public functions" {
        It "has a test file for <BaseName>" -TestCases $publicFunctionFiles {
            $expectedTestFile = "$BaseName.Unit.Tests.ps1"
            $testFiles.Name | Should -Contain $expectedTestFile
        }

        It "exports <BaseName>" -TestCases $publicFunctionFiles {
            $expectedFunctionName = $BaseName
            $module.ExportedCommands.keys | Should -Contain $expectedFunctionName
        }
    }

    Describe "Private functions" {
        # TODO: have one test file for each private function
        <# It "has a test file for <BaseName>" -TestCases $privateFunctionFiles {
                param($BaseName)
                $expectedTestFile = "$BaseName.Unit.Tests.ps1"
                $testFiles.Name | Should -Contain $expectedTestFile
            } #>

        It "does not export <BaseName>" -TestCases $privateFunctionFiles {
            $expectedFunctionName = $BaseName
            $module.ExportedCommands.keys | Should -Not -Contain $expectedFunctionName
        }
    }

    <#
    Describe "Classes" {
        foreach ($class in ([AtlassianPS.ServerData].Assembly.GetTypes() | Where-Object IsClass)) {
            It "has a test file for $class" {
                $expectedTestFile = "$class.Unit.Tests.ps1"
                $testFiles.Name | Should -Contain $expectedTestFile
            }
        }
    }

    Describe "Enumeration" {
        foreach ($enum in ([AtlassianPS.ServerData].Assembly.GetTypes() | Where-Object IsEnum)) {
            It "has a test file for $enum" {
                $expectedTestFile = "$enum.Unit.Tests.ps1"
                $testFiles.Name | Should -Contain $expectedTestFile
            }
        }
    }
#>

    Describe "Project stucture" {
        It "has all the public functions as a file in 'JiraPS/Public'" {
            $publicFunctions = (Get-Module -Name JiraPS).ExportedFunctions.Keys

            foreach ($function in $publicFunctions) {
                (Get-ChildItem "$moduleRoot/JiraPS/Public").BaseName | Should -Contain $function
            }
        }
    }
}
