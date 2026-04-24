#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "ConvertTo-JiraTable" -Tag 'Unit' {
        BeforeAll {
            $script:n = [System.Environment]::NewLine
            $script:obj = [PSCustomObject] @{
                A = '123'
                B = '456'
                C = '789'
            }

            $script:obj2 = [PSCustomObject] @{
                A = '12345'
                B = '12345'
                C = '12345'
                D = '12345'
            }
        }

        It "Translates an object into a String" {

            $expected = "||A||B||C||$n|123|456|789|"

            $string = ConvertTo-JiraTable -InputObject $obj
            $string | Should -Be $expected
        }

        It "Handles positional parameters correctly" {
            $expected = "||A||B||C||$n|123|456|789|"

            ConvertTo-JiraTable -Property A, B, C $obj | Should -Be $expected
            ConvertTo-JiraTable A, B, C $obj | Should -Be $expected
        }

        It "Handles pipeline input correctly" {
            $expected = "||A||B||C||D||$n|12345|12345|12345|12345|"

            $obj2 | ConvertTo-JiraTable | Should -Be $expected
        }

        It "Accepts multiple input objects" {

            $expected1 = "||A||B||C||$n|123|456|789|$n|12345|12345|12345|"

            $expected2 = "||A||B||C||D||$n|12345|12345|12345|12345|$n|123|456|789| |"

            $obj, $obj2 | ConvertTo-JiraTable | Should -Be $expected1
            $obj2, $obj | ConvertTo-JiraTable | Should -Be $expected2
        }

        It "Returns only selected properties if the -Property argument is passed" {
            Mock Get-Process {
                # Rather than actually running Get-Process, we'll use a known example of what
                # its output *could* be, so we can produce repeatable results.
                [PSCustomObject] @{
                    CompanyName = 'Microsoft Corporation'
                    Handle      = 5368
                    Id          = 4496
                    MachineName = '.'
                    Name        = 'explorer'
                    Path        = 'C:\Windows\Explorer.EXE'
                }
            }

            $expected1 = "||Name||Id||$n|explorer|4496|"
            $expected2 = "||Name||CompanyName||Id||MachineName||Handle||$n|explorer|Microsoft Corporation|4496|.|5368|"

            Get-Process | ConvertTo-JiraTable -Property Name, Id | Should -Be $expected1
            Get-Process | ConvertTo-JiraTable -Property Name, CompanyName, Id, MachineName, Handle | Should -Be $expected2
        }

        It "Returns an object's default properties if the -Property argument is not passed" {
            Mock Get-Process {
                $obj = [PSCustomObject] @{
                    CompanyName = 'Microsoft Corporation'
                    Handle      = 5368
                    Id          = 4496
                    MachineName = '.'
                    Name        = 'explorer'
                    Path        = 'C:\Windows\Explorer.EXE'
                }

                # Since we're mocking this with a PSCustomObject, we need to define its default property set
                [String[]] $DefaultProperties = @('Name', 'Id')
                $defaultPropertySet = New-Object -TypeName System.Management.Automation.PSPropertySet -ArgumentList 'DefaultDisplayPropertySet', $DefaultProperties
                $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]] $defaultPropertySet
                Add-Member -InputObject $obj -MemberType MemberSet -Name PSStandardMembers -Value $PSStandardMembers -Force

                Write-Output $obj
            }

            $expected = "||Name||Id||$n|explorer|4496|"

            Get-Process | ConvertTo-JiraTable | Should -Be $expected
        }

        It "Returns ALL object's default properties if the -Property argument is not passed" {
            Mock Get-Process {
                $obj = [PSCustomObject] @{
                    CompanyName = 'Microsoft Corporation'
                    Handle      = 5368
                    Id          = 4496
                    MachineName = '.'
                    Name        = 'explorer'
                    Path        = 'C:\Windows\Explorer.EXE'
                }

                [String[]] $DefaultProperties = @('Name', 'Id')
                $defaultPropertySet = New-Object -TypeName System.Management.Automation.PSPropertySet -ArgumentList 'DefaultDisplayPropertySet', $DefaultProperties
                $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]] $defaultPropertySet
                Add-Member -InputObject $obj -MemberType MemberSet -Name PSStandardMembers -Value $PSStandardMembers -Force

                Write-Output $obj
            }

            $expected = "||CompanyName||Handle||Id||MachineName||Name||Path||$n|Microsoft Corporation|5368|4496|.|explorer|C:\Windows\Explorer.EXE|"

            Get-Process | ConvertTo-JiraTable -Property * | Should -Be $expected
        }

        Context "Backward-compatibility alias 'Format-Jira'" {
            It "Is exported as an alias of ConvertTo-JiraTable" {
                $aliasCommand = Get-Command -Name Format-Jira -ErrorAction Stop

                $aliasCommand.CommandType | Should -Be 'Alias'
                $aliasCommand.Source | Should -Be 'JiraPS'
                $aliasCommand.Definition | Should -Be 'ConvertTo-JiraTable'
            }

            It "Produces identical output when invoked via the alias" {
                $expected = $obj | ConvertTo-JiraTable
                $actual = $obj | Format-Jira

                $actual | Should -Be $expected
            }
        }

        Context "Cloud-deployment warning" {
            BeforeAll {
                Mock Test-JiraCloudServer -ModuleName JiraPS { $true }
            }

            It "Emits a warning that mentions Cloud, ADF, and the v3 mismatch" {
                $null = ConvertTo-JiraTable -InputObject $obj -WarningVariable warn -WarningAction SilentlyContinue

                $warn | Should -Not -BeNullOrEmpty
                # Match the user-facing pieces of the message rather than its exact wording,
                # so the message can evolve without breaking the test.
                ($warn -join ' ') | Should -Match 'Jira Cloud'
                ($warn -join ' ') | Should -Match 'wiki markup'
                ($warn -join ' ') | Should -Match 'ADF|Atlassian Document Format'
            }

            It "Still produces correct output despite the warning" {
                $expected = "||A||B||C||$n|123|456|789|"

                $actual = ConvertTo-JiraTable -InputObject $obj -WarningAction SilentlyContinue

                $actual | Should -Be $expected
            }

            It "Emits the warning only once per invocation, regardless of pipeline length" {
                $null = $obj, $obj2, $obj | ConvertTo-JiraTable -WarningVariable warn -WarningAction SilentlyContinue

                @($warn).Count | Should -Be 1
            }

            It "Honors -WarningAction SilentlyContinue (warning stream is silent)" {
                # PowerShell's `-WarningVariable` still captures warnings even when -WarningAction
                # is SilentlyContinue or Ignore, so we test the user-visible contract directly:
                # the warning STREAM (stream 3) is empty when suppression is requested.
                $output = ConvertTo-JiraTable -InputObject $obj -WarningAction SilentlyContinue 3>&1

                @($output | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }).Count |
                    Should -Be 0
            }
        }

        Context "Inner deployment-lookup warnings do not leak" {
            # The real Test-JiraCloudServer is exercised here so its `-WarningAction` propagation
            # to the underlying Get-JiraServerInformation call is part of what we're verifying.
            # (Pester mocks do not propagate CommonParameter preferences to the mock body, so
            # mocking Test-JiraCloudServer directly cannot test this.)
            BeforeAll {
                Mock Get-JiraServerInformation -ModuleName JiraPS {
                    # Simulate the fallback path: Get-JiraServerInformation emits a transient
                    # Write-Warning when the API is unreachable, then returns a fallback object.
                    # We force DeploymentType = Cloud so we can also confirm the OUTER
                    # Cloud-deployment warning still surfaces.
                    Write-Warning "[Get-JiraServerInformation] Could not retrieve server information: simulated transient failure"
                    [PSCustomObject]@{
                        PSTypeName     = 'JiraPS.ServerInfo'
                        DeploymentType = 'Cloud'
                    }
                }
            }

            It "Suppresses the inner Write-Warning while keeping the outer Cloud-deployment warning" {
                $output = ConvertTo-JiraTable -InputObject $obj 3>&1
                $warnings = @($output | Where-Object { $_ -is [System.Management.Automation.WarningRecord] })

                @($warnings | Where-Object { $_.Message -match 'Could not retrieve server information' }).Count |
                    Should -Be 0
                @($warnings | Where-Object { $_.Message -match 'Jira Cloud' }).Count |
                    Should -Be 1
            }
        }

        Context "Data Center / Server (no warning)" {
            BeforeAll {
                Mock Test-JiraCloudServer -ModuleName JiraPS { $false }
            }

            It "Does not emit a warning" {
                $null = ConvertTo-JiraTable -InputObject $obj -WarningVariable warn -WarningAction SilentlyContinue

                $warn | Should -BeNullOrEmpty
            }

            It "Produces the same output as the no-warning baseline" {
                $expected = "||A||B||C||$n|123|456|789|"

                ConvertTo-JiraTable -InputObject $obj | Should -Be $expected
            }
        }

        Context "No session / unknown deployment (no warning, no throw)" {
            BeforeAll {
                # Simulate the offline case: Test-JiraCloudServer fails because Get-JiraConfigServer
                # has no value. The cmdlet must remain usable as a pure offline string formatter.
                Mock Test-JiraCloudServer -ModuleName JiraPS { throw 'No JiraConfigServer set' }
            }

            It "Does not throw and does not emit a warning" {
                { ConvertTo-JiraTable -InputObject $obj -WarningVariable warn -WarningAction SilentlyContinue } |
                    Should -Not -Throw

                $null = ConvertTo-JiraTable -InputObject $obj -WarningVariable warn -WarningAction SilentlyContinue
                $warn | Should -BeNullOrEmpty
            }

            It "Still produces correct output" {
                $expected = "||A||B||C||$n|123|456|789|"

                ConvertTo-JiraTable -InputObject $obj | Should -Be $expected
            }
        }
    }
}
