#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    Import-Module "$PSScriptRoot/Helpers/TestTools.psm1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource
    $script:moduleRoot = Resolve-ProjectRoot

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

Describe "General project validation" -Tag Unit {
    BeforeDiscovery {
        $script:module = Get-Module JiraPS
        $script:testFiles = Get-ChildItem $PSScriptRoot -Include "*.Tests.ps1" -Recurse
        $script:publicFunctionFiles = $module.ExportedFunctions.Keys
        $script:privateFunctionFiles = $module.Invoke(
            {
                Get-Command -Module JiraPS |
                Where-Object {
                    $_.Name -notin $publicFunctionFiles -and
                    $_.CommandType -ne 'Alias'
                }
            }
        ).Name
    }

    Describe "Public functions" {
        It "has a test file for <_>" -TestCases $publicFunctionFiles {
            $expectedTestFile = "$_.Unit.Tests.ps1"
            $testFiles.Name | Should -Contain $expectedTestFile
        }

        It "exports <_>" -TestCases $publicFunctionFiles {
            $expectedFunctionName = $_
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
        It "has private functions" {
            $privateFunctionFiles.Count | Should -BeGreaterThan 0
        }

        It "does not export <_>" -TestCases $privateFunctionFiles {
            $expectedFunctionName = $_
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
        It "has public functions as exported by the module" {
            $exportedFunctions = $module.ExportedFunctions.Keys

            foreach ($function in $exportedFunctions) {
                $function | Should -BeIn $publicFunctionFiles
            }
        }

        It "has all the public functions as a file in 'JiraPS/Public'" {
            $publicFunctions = $module.ExportedFunctions.Keys

            foreach ($function in $publicFunctions) {
                (Get-ChildItem "$moduleRoot/JiraPS/Public").BaseName | Should -Contain $function
            }
        }
    }
}
