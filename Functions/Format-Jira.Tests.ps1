$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {
    Describe "Format-Jira" {
        $n = [System.Environment]::NewLine
        $obj = [PSCustomObject] @{
            A = '123';
            B = '456';
            C = '789';
        }

        $obj2 = [PSCustomObject] @{
            A = '12345'
            B = '12345'
            C = '12345'
            D = '12345'
        }

        It "Translates an object into a String" {

            $expected = "||A||B||C||$n|123|456|789|"
            
            $string = Format-Jira -InputObject $obj
            $string | Should Be $expected
        }

        It "Handles positional parameters correctly" {
            $expected = "||A||B||C||$n|123|456|789|"
            
            Format-Jira -Property A,B,C $obj | Should Be $expected
            Format-Jira A,B,C $obj | Should Be $expected
        }

        It "Handles pipeline input correctly" {
            $expected = "||A||B||C||D||$n|12345|12345|12345|12345|"

            $obj2 | Format-Jira | Should Be $expected
        }

        It "Accepts multiple input objects" {

            $expected1 = "||A||B||C||$n|123|456|789|$n|12345|12345|12345|"

            $expected2 = "||A||B||C||D||$n|12345|12345|12345|12345|$n|123|456|789| |"
            
            $obj,$obj2 | Format-Jira | Should Be $expected1
            $obj2,$obj | Format-Jira | Should Be $expected2
        }

        It "Returns only selected properties if the -Property argument is passed" {
            Mock Get-Process {
                [PSCustomObject] @{
                    CompanyName = 'Microsoft Corporation'
                    Handle      = 5368;
                    Id          = 4496;
                    MachineName = '.'
                    Name        = 'explorer';
                    Path        = 'C:\Windows\Explorer.EXE';
                }
            }

            $expected1 = "||Name||Id||$n|explorer|4496|"
            $expected2 = "||Name||CompanyName||Id||MachineName||Handle||$n|explorer|Microsoft Corporation|4496|.|5368|"

            Get-Process | Format-Jira -Property Name,Id | Should Be $expected1
            Get-Process | Format-Jira -Property Name,CompanyName,Id,MachineName,Handle | Should Be $expected2
        }
    }
}