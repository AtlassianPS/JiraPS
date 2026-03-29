#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertTo-%RESOURCE%" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'

            # TODO: Add sample JSON response from JIRA API (remove personal data)
            $sampleJson = @"
{
    "id": "123",
    "name": "Example",
    "created": "2025-01-01T00:00:00.000Z",
    "author": {
        "name": "JonDoe",
        "displayName": "Doe, Jon"
    }
}
"@

            $script:sampleObject = ConvertFrom-Json -InputObject $sampleJson
            #endregion Definitions

            #region Mocks
            # Converter functions typically don't need mocks
            # Add mocks here if the converter calls other functions
            #endregion Mocks
        }

        Describe "Behavior" {
            BeforeAll {
                # Convert once for all tests in this Describe block
                $script:result = ConvertTo-%RESOURCE% -InputObject $sampleObject
            }

            Context "Object Conversion" {
                It "creates a PSObject out of JSON input" {
                    $result | Should -Not -BeNullOrEmpty
                    $result | Should -BeOfType [PSCustomObject]
                }

                It "adds the custom type name 'JiraPS.%RESOURCE%'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'JiraPS.%RESOURCE%'
                }
            }

            Context "Property Mapping" {
                # TODO: Update test cases with actual properties from your resource
                It "defines '<property>' of type '<type>' with value '<value>'" -TestCases @(
                    @{ property = "Id"; type = [string]; value = '123' }
                    @{ property = "Name"; type = [string]; value = 'Example' }
                    @{ property = "Author"; type = 'JiraPS.User'; value = 'JonDoe' }
                    @{ property = "Created"; type = [System.DateTime]; value = (Get-Date "2025-01-01T00:00:00.000Z") }
                ) {
                    # Check value (if specified)
                    if ($value) {
                        $result.$($property) | Should -Be $value
                    }
                    else {
                        $result.$($property) | Should -Not -BeNullOrEmpty
                    }

                    # Check type
                    if ($type -is [string]) {
                        # String indicates a custom type name
                        $result.$($property).PSObject.TypeNames[0] | Should -Be $type
                    }
                    else {
                        # Otherwise check .NET type
                        $result.$($property) | Should -BeOfType $type
                    }
                }
            }

            Context "Pipeline Support" {
                It "accepts input from pipeline" {
                    $pipelineResult = $sampleObject | ConvertTo-%RESOURCE%
                    $pipelineResult | Should -Not -BeNullOrEmpty
                    $pipelineResult.PSObject.TypeNames[0] | Should -Be 'JiraPS.%RESOURCE%'
                }

                It "handles array input" {
                    $multipleObjects = @($sampleObject, $sampleObject)
                    $arrayResult = $multipleObjects | ConvertTo-%RESOURCE%
                    @($arrayResult).Count | Should -Be 2
                }
            }
        }
    }
}
