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

        Context "Pure transform (no session side-effects)" {
            # ConvertTo-* cmdlets must remain deterministic, offline string transforms.
            # Any deployment-aware behavior (e.g., the planned ADF wrapping in #602)
            # belongs on the write-side cmdlets, where the actual API payload is built.
            It "Does not call Test-JiraCloudServer" {
                Mock Test-JiraCloudServer -ModuleName JiraPS { $true }

                $null = ConvertTo-JiraTable -InputObject $obj

                Should -Invoke Test-JiraCloudServer -ModuleName JiraPS -Times 0 -Exactly
            }

            It "Emits no warnings on the warning stream" {
                $output = ConvertTo-JiraTable -InputObject $obj 3>&1
                @($output | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }).Count |
                    Should -Be 0
            }
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
    }
}
