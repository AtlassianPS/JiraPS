#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource
    $script:moduleRoot = Resolve-ProjectRoot

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

Describe "General project validation" -Tag Unit {
    BeforeDiscovery {
        $script:module = Get-Module 'JiraPS'

        $manifestPath = $script:moduleToTest
        $script:testFiles = Get-ChildItem $PSScriptRoot -Include "*.Tests.ps1" -Recurse

        $script:publicFunctionFiles = (Get-ChildItem "$moduleRoot/JiraPS/Public/*.ps1").BaseName
        $script:privateFunctionFiles = (Get-ChildItem "$moduleRoot/JiraPS/Private/*.ps1").BaseName

        $manifestData = Import-PowerShellDataFile -Path $manifestPath
        $script:exportedFunctionNames = $manifestData.FunctionsToExport
    }

    Describe "Public functions" {
        Context "Function <_>" -ForEach $publicFunctionFiles {
            BeforeAll {
                $script:functionName = $_
            }
            It "has a test file" {
                $expectedTestFile = "$functionName.Unit.Tests.ps1"
                $testFiles.Name | Should -Contain $expectedTestFile
            }

            It "is exported" {
                $exportedFunctionNames | Should -Contain $functionName
            }
        }
    }

    Describe "Private functions" {
        It "has private functions" {
            $privateFunctionFiles.Count | Should -BeGreaterThan 0
        }

        Context "Function <_>" -ForEach $privateFunctionFiles {
            BeforeAll {
                $script:functionName = $_
            }
            # TODO: have one test file for each private function
            <# It "has a test file for <BaseName>" -TestCases $privateFunctionFiles {
                param($BaseName)
                $expectedTestFile = "$BaseName.Unit.Tests.ps1"
                $testFiles.Name | Should -Contain $expectedTestFile
            } #>

            It "is loaded in the module" {
                $commandInModule = $module.Invoke({ Get-Command -Name $args[0] -ErrorAction SilentlyContinue }, $functionName)

                $commandInModule | Should -Not -BeNullOrEmpty -Because "private function '$functionName' should be loaded"
            }

            It "is not exported" {
                $exportedFunctionNames | Should -Not -Contain $functionName
            }
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
        It "only exports functions from the Public folder" {
            foreach ($exportedFunctionName in $exportedFunctionNames) {
                $publicFunctionFiles | Should -Contain $exportedFunctionName -Because "exported function '$exportedFunctionName' should have a corresponding file in JiraPS/Public/"
            }
        }
    }
}
