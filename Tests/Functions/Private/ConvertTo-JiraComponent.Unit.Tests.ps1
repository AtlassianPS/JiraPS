#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraComponent" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $jiraServer = 'http://jiraserver.example.com'

            $sampleJson = @"
{
    "self": "$jiraServer/rest/api/2/component/11000",
    "id": "11000",
    "name": "test component"
}
"@
            $script:sampleObject = ConvertFrom-Json -InputObject $sampleJson
            #endregion Definitions
        }

        Describe "Behavior" {
            BeforeAll {
                $script:result = ConvertTo-JiraComponent -InputObject $sampleObject
            }

            Context "Object Conversion" {
                It "creates a PSObject out of JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                    $result | Should -BeOfType [PSCustomObject]
                }

                It "adds custom type 'JiraPS.Component'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'JiraPS.Component'
                }
            }

            Context "Inputs" {
                It "converts multiple attachments from array input" {
                    ConvertTo-JiraComponent -InputObject $sampleObject, $sampleObject | Should -HaveCount 2
                }

                It "accepts input from pipeline" {
                    $sampleObject, $sampleObject | ConvertTo-JiraComponent | Should -HaveCount 2
                }
            }

            Context "Property Mapping" {
                It "defines '<property>' of type '<type>' with value '<value>'" -TestCases @(
                    @{ property = "Id"; type = [string]; value = 11000 }
                    @{ property = "Name"; type = [string]; value = 'test component' }
                    @{ property = "RestUrl"; type = [string]; value = $null }
                ) {
                    if ($value) { $result.$($property) | Should -Be $value }
                    else { $result.$($property) | Should -Not -BeNullOrEmpty }

                    if ($type -is [string]) {
                        $result.$($property).PSObject.TypeNames[0] | Should -Be $type
                    }
                    else { $result.$($property) | Should -BeOfType $type }
                }
            }
        }
    }
}
