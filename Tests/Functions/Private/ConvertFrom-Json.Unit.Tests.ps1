#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "ConvertFrom-Json" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:sampleJson = '{"id":"issuetype","name":"Issue Type","custom":false,"orderable":true,"navigable":true,"searchable":true,"clauseNames":["issuetype","type"],"schema":{"type":"issuetype","system":"issuetype"}}'
            $script:sampleObject = [PSCustomObject] @{
                id          = 'issuetype'
                name        = 'Issue Type'
                custom      = $false
                orderable   = $true
                navigable   = $true
                searchable  = $true
                clauseNames = @('issuetype', 'type')
                schema      = [PSCustomObject] @{
                    type   = 'issuetype'
                    system = 'issuetype'
                }
            }
            #endregion Definitions

            #region Mocks
            #endregion Mocks
        }

        It "only overwrites the native ConvertFrom-Json on PSv5" {
            $command = Get-Command -Name ConvertFrom-Json

            if ($PSVersionTable.PSVersion.Major -lt 6) {
                $command.Source | Should -Be "JiraPS"
            }
            else {
                $command.Source | Should -Be "Microsoft.PowerShell.Utility"
            }
        }

        Describe "Signature" -Skip:($PSVersionTable.PSVersion.Major -ge 6) {
            BeforeAll {
                $script:command = Get-Command -Name ConvertFrom-Json -Module JiraPS
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "InputObject"; type = "Object[]" }
                    @{ parameter = "MaxJsonLength"; type = "Int" }
                ) {
                    $command | Should -HaveParameter $parameter

                    #ToDo:CustomClass
                    # can't use -Type as long we are using `PSObject.TypeNames.Insert(0, 'JiraPS.Filter')`
                    (Get-Member -InputObject $command.Parameters.Item($parameter)).Attributes | Should -Contain $typeName
                }
            }

            Context "Default Values" {
                It "parameter '<parameter>' has a default value of '<defaultValue>'" -TestCases @(
                    @{ parameter = "MaxJsonLength"; defaultValue = "[Int]::MaxValue" }
                ) {
                    $command | Should -HaveParameter $parameter -DefaultValue $defaultValue
                }
            }

            Context "Mandatory Parameters" {
                It "parameter '<parameter>' is mandatory" -TestCases @(
                    @{ parameter = "InputObject" }
                ) {
                    $command | Should -HaveParameter $parameter -Mandatory
                }
            }
        }

        Describe "Behavior" -Skip:($PSVersionTable.PSVersion.Major -ge 6) {
            Context "Object Conversion" {
                It "creates PSObject from JSON input" {
                    $result = ConvertFrom-Json -InputObject $sampleJson
                    $result | Should -Not -BeNullOrEmpty
                }

                It "produces same output as native ConvertFrom-Json" {
                    # Make sure we've got our head screwed on straight. If it's a short enough JSON string that ConvertFrom-Json can handle it, this function should provide identical output to the native one.
                    $custom = ConvertFrom-Json -InputObject $sampleJson
                    $native = Microsoft.PowerShell.Utility\ConvertFrom-Json -InputObject $sampleJson

                    foreach ($p in $custom.PSObject.Properties.Name) {
                        # Force converting everything to a string isn't the best test of equality, but it's good enough for what we need here.
                        "$($custom.$p)" | Should -Be "$($native.$p)"
                    }
                }
            }

            Context "Property Mapping" {
                It "maps all JSON properties correctly" {
                    $result = ConvertFrom-Json -InputObject $sampleJson
                    $result.id | Should -Be 'issuetype'
                    $result.name | Should -Be 'Issue Type'
                    $result.custom | Should -Be $false
                }
            }

            Context "Type Conversion" {
                It "converts nested objects correctly" {
                    $result = ConvertFrom-Json -InputObject $sampleJson
                    $result.schema | Should -Not -BeNullOrEmpty
                    $result.schema.type | Should -Be 'issuetype'
                }

                It "converts arrays correctly" {
                    $result = ConvertFrom-Json -InputObject $sampleJson
                    $result.clauseNames | Should -Not -BeNullOrEmpty
                    $result.clauseNames.Count | Should -Be 2
                }
            }

            Context "Pipeline Support" {
                It "does not crash on null or empty input" {
                    { ConvertFrom-Json -InputObject '' } | Should -Not -Throw
                }

                It "accepts pipeline input" {
                    { @($sampleJson, $sampleJson) | ConvertFrom-Json } | Should -Not -Throw
                }

                It "processes multiple JSON strings from pipeline" {
                    $result = @($sampleJson, $sampleJson) | ConvertFrom-Json
                    $result | Should -HaveCount 2
                }
            }
        }
    }
}
