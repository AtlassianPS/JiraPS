#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    $script:ThisTest = "ConvertFrom-Json"

    . "$PSScriptRoot/../Helpers/Resolve-ModuleSource.ps1"
    $script:moduleToTest = Resolve-ModuleSource

    $dependentModules = Get-Module | Where-Object { $_.RequiredModules.Name -eq 'JiraPS' }
    $dependentModules, "JiraPS" | Remove-Module -Force -ErrorAction SilentlyContinue
    Import-Module $moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPS {
    Describe "$ThisTest" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/Shared.ps1"

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
        }

        It "only overwrites the native ConvertFrom-Json on PSv5" {
            $command = Get-Command -Name $ThisTest

            if ($PSVersionTable.PSVersion.Major -lt 6) {
                $command.Source | Should -Be "JiraPS"
            }
            else {
                $command.Source | Should -Be "Microsoft.PowerShell.Utility"
            }
        }

        Describe "Signature" -Skip:($PSVersionTable.PSVersion.Major -ge 6) {
            BeforeAll {
                $script:command = Get-Command -Name $ThisTest
            }

            It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                @{ parameter = "InputObject"; type = "Object[]" }
                @{ parameter = "MaxJsonLength"; type = "Int" }
            ) {
                $command | Should -HaveParameter $parameter

                #ToDo:CustomClass
                # can't use -Type as long we are using `PSObject.TypeNames.Insert(0, 'JiraPS.Filter')`
                (Get-Member -InputObject $command.Parameters.Item($parameter)).Attributes | Should -Contain $typeName
            }

            It "parameter '<parameter>' has a default value of '<defaultValue>'" -TestCases @(
                @{ parameter = "MaxJsonLength"; defaultValue = "[Int]::MaxValue" }
            ) {
                $command | Should -HaveParameter $parameter -DefaultValue $defaultValue
            }

            It "parameter '<parameter>' is mandatory" -TestCases @(
                @{ parameter = "InputObject" }
            ) {
                $command | Should -HaveParameter $parameter -Mandatory
            }
        }

        Describe "Behavior" {
            It "Creates a PSObject out of JSON input" {
                $sampleObject = ConvertFrom-Json -InputObject $sampleJson

                $sampleObject | Should -Be $sampleObject
            }

            It "Does not crash on a null or empty input" {
                { ConvertFrom-Json -InputObject '' } | Should -Not -Throw
            }

            It "Accepts pipeline input" {
                { @($sampleJson, $sampleJson) | ConvertFrom-Json } | Should -Not -Throw
            }

            It "Provides the same output as ConvertFrom-Json for JSON strings the latter can handle" {
                # Make sure we've got our head screwed on straight. If it's a short enough JSON string that ConvertFrom-Json can handle it, this function should provide identical output to the native one.

                $custom = ConvertFrom-Json -InputObject $sampleJson
                $native = Microsoft.PowerShell.Utility\ConvertFrom-Json -InputObject $sampleJson
                # $custom | Should -Be $native

                foreach ($p in $custom.PSObject.Properties.Name) {
                    # Force converting everything to a string isn't the best test of equality, but it's good enough for what we need here.
                    "$($custom.$p)" | Should -Be "$($native.$p)"
                }
            }
        }
    }
}
